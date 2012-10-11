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

class User
  include Mongoid::Document

  field :accounts, type: Hash

  devise :rememberable, :trackable

  ## Rememberable
  field :remember_created_at, type: Time
  field :remember_token,      type: String

  ## Trackable
  field :sign_in_count,      type: Integer, default: 0
  field :current_sign_in_at, type: Time
  field :last_sign_in_at,    type: Time
  field :current_sign_in_ip, type: String
  field :last_sign_in_ip,    type: String

  # TODO Clean fields after ebook deletion
  field :purchases, type: Hash, default: {}
  field :readings, type: Hash, default: {}
  field :number_of_bookmarks, type: Hash, default: {}

  field :last_import_at, type: Hash, default: {}

  has_and_belongs_to_many :books, class_name: 'Ebook::Base', dependent: :nullify

  has_many :bookmarks, dependent: :destroy
  has_many :reading_positions, dependent: :destroy
  has_many :annotations, dependent: :destroy

  def reading_position(book)
     ReadingPosition.for_book_and_user(book, self)
  end

  # Url of users book api
  # TODO id is the same for all bookstores
  #
  def tea_library_url bookstore_id
    if accounts[bookstore_id]
      Gaston.api.paths.publications.gsub(':user_id', accounts[bookstore_id]['id'])
    end
  end

  # Import user books if last import is older than 5 minutes
  #
  def should_reimport_books?(bookstore_id)
    last = last_import_at[bookstore_id]
    last.nil? || last < (Time.now - 5.minutes)
  end

  # Import/Update/Remove all users books from TEA api
  #
  # TODO : remove books that are no longer available
  #
  def import_books! cookie, bookstore_id
    hydra = Typhoeus::Hydra.hydra
    request = TeaApi::Request.build(
      url: tea_library_url(bookstore_id),
      method: :get,
      cookie: cookie
    )
    hydra.queue(request)
    request.on_complete do |response|
      case response.code
      when 403
        raise JSON.parse(response.body).inspect
      when 200
        resp = JSON.parse(response.body).with_indifferent_access
        resp[:results].each do |book|
          e = Ebook::Base.create_from_api book, self
          e.enqueue_download cookie if e && !e.file.present?
        end
      end
    end
    self.last_import_at[bookstore_id] = Time.now
    self.save
    hydra.run
  end

  # TODO id is the same for all bookstores
  def self.find_or_create_from_tea_session(tea_session)
    if user = User.where("accounts.#{tea_session.bookstore}.id" => tea_session.id).one
      user.accounts[tea_session.bookstore] = tea_session.to_user_account
      user.save
      user
    else
      User.create(accounts: {"#{tea_session.bookstore}" => tea_session.to_user_account})
    end
  end

  # Return account informations for the given bookstore
  def account bookstore_id
    accounts[bookstore_id]
  end

  def create_uploaded_purchase!(book)
    purchases[book.id.to_s] = {
      type: 'user_uploaded',
      date: Time.now.to_s
    }
    save!
  end

  def enqueue_import_books cookie, bookstore_id
    if Resque.enqueue(ImportBooksWorker, id, bookstore_id, cookie)
      self.last_import_at[bookstore_id] = Time.now
      self.save
    end
  end
end
