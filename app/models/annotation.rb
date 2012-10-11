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

class Annotation < BookLocation
  field :end_xpath,       type: String

  field :start_offset,    type: Integer, default: 0
  field :end_offset,      type: Integer, default: 0

  field :note,            type: String

  validates_presence_of :note, allow_blank: false

  attr_accessible :component_name, :start_xpath, :end_xpath, :start_offset, :note

  protected

  def build_cfi!
    self.epub_cfi = book.cfi.range(component_name, start_xpath, start_offset, end_xpath, end_offset)
  end

end
