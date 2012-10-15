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


class Ebook::Epub::Chapter
  include Mongoid::Document
  include Mongoid::Tree

  referenced_in :ebook, class_name: 'Ebook::Epub', inverse_of: :chapters

  field :title
  field :src
  field :position, type: Integer

  default_scope order_by([:position, :asc])

  # Create chapter and his children from a peregrin chapter
  #
  def self.create_chapter(ebook, chapter)
    root = Ebook::Epub::Chapter.create!(
      title: chapter.title,
      src: self.src_from_components(ebook, chapter),
      position: chapter.position,
      ebook: ebook
    )
    chapter.children.each do |child|
      root.children << Ebook::Epub::Chapter.create_chapter(ebook, child)
    end
    root
  end

  # FIXME UGLY
  # Chapters have path relative to nav or ncs file,
  # but components have path relative to opf file
  # We need to harmonize this for Monocle Chapters managment
  def self.src_from_components(ebook, chapter)
    match = /^.*#{chapter.src.gsub(/\#.*?$/, '')}.*/
    hash = chapter.src.gsub(/^([^#]*)/, '')
    src = ebook.components.where(src: match).first.try(:src)
    "#{src}#{hash}"
  end

  def as_json(options = {})
    options.merge!(methods: [:children])
    super(options)
  end
end
