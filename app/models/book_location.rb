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


class BookLocation
  include Mongoid::Document

  field :component_name,  type: String
  field :start_xpath,     type: String, default: "/html/body/p"
  field :device,          type: String

  field :epub_cfi,        type: String
  field :created_at,      type: Time
  field :updated_at,      type: Time

  before_save :build_cfi!, if: ->(loc) { loc.component_name }
  before_save :create_timestamps!

  referenced_in :user
  referenced_in :book, class_name: 'Ebook::Epub'

  validates_presence_of :user_id
  validates_presence_of :book_id
  validates_presence_of :component_name, allow_blank: false, if: ->(loc) { loc.book && loc.book.converted? }

  scope :for_user, ->(user) { where(user_id: user.id) }

  def to_param
    id.to_s
  end

  protected

  def build_cfi!
    self.epub_cfi = book.cfi.path(start_xpath, component_name) unless epub_cfi_changed?
  end

  def create_timestamps!
    self.created_at = Time.now if new_record?
    self.updated_at = Time.now unless updated_at_changed?
  end

end
