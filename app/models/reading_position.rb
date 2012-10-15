# encoding: utf-8

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


class ReadingPosition < Bookmark
  field :locus,       type: Hash
  field :percentage,  type: Float

  attr_accessible :book, :component_name, :start_xpath, :locus, :epub_cfi, :updated_at, :percentage

  validates_uniqueness_of :book_id, scope: [:user_id]

  def self.for_book_and_user(book, user, new_record_options = {})
    where(user_id: user.id, book_id: book.id).first || default_reading_position(book, user, new_record_options)
    # TeaApi::UserInfoSynchronizer.new(user).refresh_book(book) do
    #   where(user_id: user.id, book_id: book.id).first || default_reading_position(book, user)
    # end
  end


  def self.create_or_update_from_api(book_api_id, user, api_data = {})
    data = api_data ? api_data.dup : {}
    book = Ebook::Epub.find_or_initialize_from_api(book_api_id)

    if position = where(user_id: user.id, book_id: book.id).first
      position.update_from_api(data)
    else
      position = default_reading_position(book, user, data)
    end

    position
  end

  def update_from_api(data)
    return unless data[:updated_at]
    remote_date = data[:updated_at].is_a?(String) ? Time.parse(data[:updated_at]) : data[:updated_at]

    update_attributes(data) if remote_date  > updated_at
  end

  def as_json(options = {})
    if options.delete(:minimal)
      options.merge!(only: %w[percentage updated_at])
    end

    super(options)
  end


  protected

  def self.default_reading_position(book, user, opts = {})
    position = new(opts.merge(book: book))
    position.user = user
    position.component_name = book.components.first.src unless book.components.empty?
    position.save!
    position
  end

end
