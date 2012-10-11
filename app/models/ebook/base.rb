# Copyright (C) 2012  TEA, the ebook alternative <http://www.tea-ebook.com/>
# 
# This file is part of TeaBook Open Reader
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, version 3.0 of the License.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 
# An additional permission has been granted as a special exception 
# to the GNU General Public Licence. 
# You should have received a copy of this exception. If not, see 
# <https://github.com/TEA-ebook/teabook-open-reader/blob/master/GPL-3-EXCEPTION>.



# encoding: utf-8

class Ebook::Base
  include Mongoid::Document
  include Mongoid::Timestamps

  field :api_id
  field :bookstore_id
  field :format, default: 'epub'
  field :title
  field :authors, type: Array, default: []
  field :publisher, type: Hash, default: {}
  field :subtitle
  field :language
  field :license, default: "none"
  field :descriptions, type: Array, default: []
  field :bytesize, type: Integer
  field :source
  field :direction

  mount_uploader :file, EbookUploader
  mount_uploader :cover, CoverUploader

  has_and_belongs_to_many :users, inverse_of: :books
  has_many :bookmarks,          inverse_of: :book,  dependent: :destroy
  has_many :annotations,        inverse_of: :book,  dependent: :destroy
  has_many :reading_positions,  inverse_of: :book,  dependent: :destroy

  scope :bookstore, ->(bookstore_id) { where(bookstore_id: bookstore_id)}

  after_destroy :clean_fs
  before_save :set_uploaded_state,  if: 'created?'

  validates_presence_of :format, :source

  # FIXME transitions logic
  state_machine initial: :created do
    event :uploaded do
      transition all => :uploaded
    end
    event :download_error do
      transition all => :download_error
    end
    event :extracting do
      transition all => :extracting
    end
    event :extracted do
      transition all => :extracted
    end
    event :extract_error do
      transition all => :extract_error
    end
    event :converting do
      transition all => :converting
    end
    event :converted do
      transition all => :converted
    end
    event :convert_error do
      transition all => :convert_error
    end
    after_transition on: :uploaded, do: :enqueue_extract_epub, if: lambda{|e| e.is_a? Ebook::Epub}
    after_transition on: :converted, do: :store_bytesize, if: lambda{|e| e.is_a? Ebook::Epub}
  end

  def to_param
    id.to_s
  end

  # Return the base directory path for this ebook
  #
  # @return String
  def base_dir_path
    File.join(Rails.root, file.store_dir)
  end

  # Create Ebook::Epub from TEA api
  # Later, this method will handle other types of Ebook, PDF for example
  #
  def self.create_from_api(json, user)
    json = json.with_indifferent_access
    json[:format].downcase!
    return unless json[:format].present?

    case json[:format]
      when 'epub'
        book = Ebook::Epub.find_or_initialize_from_api(json[:id])
        ReadingPosition.create_or_update_from_api(json[:id], user)
        book.user_ids << user.id
        cover_url = json.delete(:cover)
        book.remote_cover_url = cover_url if cover_url != book.remote_cover_url
        book.update_attributes json.slice(
          :bookstore_id, :title, :subtitle, :language, :license,
          :authors, :publisher, :descriptions
        )
        user.purchases[book.id.to_s]           = json[:purchase]
        user.number_of_bookmarks[book.id.to_s] = json[:number_of_bookmarks]
        user.save

        book
      else
        # FIXME Import pdf ?
        nil
      end
  end

  def tea_download_url
    if api_id
      Gaston.api.paths.download.gsub(':book_id', api_id)
    end
  end

  # Download Ebook file from the TEA API
  #
  def download!(cookie)
    hydra = Typhoeus::Hydra.hydra
    request = TeaApi::Request.build(
      url: tea_download_url,
      method: :get,
      cookie: cookie,
      follow_location: true,
      disable_ssl_host_verification: true, # FIXME ?
      disable_ssl_peer_verification: true  # FIXME ?
    )
    hydra.queue(request)
    request.on_complete do |response|
      case response.code
      when 200
        f = File.new "/tmp/#{self.id}.epub", 'wb'
        f.write response.body
        f.close
        self.file = File.open f
        self.save!
        File.delete f
      else
        Rails.logger.error "Fail to download #{self.title} : #{response.inspect}"
        self.download_error
      end
    end
    hydra.run
  end

  # Enqueue ebook download
  def enqueue_download(cookie)
    Resque.enqueue(DownloadEbookWorker, id, cookie)
  end

private

  def clean_fs
    FileUtils.rm_rf(base_dir_path)
    FileUtils.rm_rf(cover.store_dir) if cover.present?
  end

  def set_uploaded_state
    self.uploaded if self.file.present?
  end

end
