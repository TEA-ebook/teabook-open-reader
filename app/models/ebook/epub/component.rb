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

class Ebook::Epub::Component
  include Mongoid::Document

  IMG_REGEXP = /^image\/(png|jpg|jpeg|gif|bmp)/
  SVG_REGEXP = /^image\/svg/  # Officially, image/svg+xml, but we accept image/svg variants

  embedded_in :ebook, class_name: 'Ebook::Epub'

  field :properties, type: Hash
  field :media_type
  field :src

  # Useful to include ebook_id in json representation
  #
  def ebook_id
    ebook.id
  end

  def as_json(options = {})
    options.merge!(methods: :content)
    super(options)
  end

  # Is it a binary image?
  def image?
    media_type =~ IMG_REGEXP
  end

  # Is it a SVG image?
  def svg?
    media_type =~ SVG_REGEXP
  end

  # Get content from filesystem
  #
  def content
    @content ||= File.read(ebook.component_path(self))
  rescue Errno::ENOENT => error
    Rails.logger.error "File not found: #{error}"
    "<html></html>"
  end

  # Extract the dimensions for fixed layout component
  #
  # Warning: be sure to call extract_dimensions before create_image_component
  # as it works on the raw image, not the embedding HTML page.
  #
  def extract_dimensions
    if svg?
      doc = Nokogiri::XML(content)
      doc.css('svg').each do |svg|
        if box = svg['viewBox']
          w, h = box.split(/\s+/)[-2, 2]
          self.properties["dimensions"] = "#{w}x#{h}"
        end
      end
    elsif image?
      image = MiniMagick::Image.open(ebook.component_path(self))
      self.properties["dimensions"] = image["%wx%h"]
    else
      doc = Nokogiri::HTML(content)
      doc.css("meta[name=viewport]").each do |meta|
        content = meta["content"] || ""
        w = content.scan(/width\s*=\s*(\d+)/).flatten.first
        h = content.scan(/height\s*=\s*(\d+)/).flatten.first
        self.properties["dimensions"] = "#{w}x#{h}" if w.present? && h.present?
      end
    end
  end

  # Raw images are embedded in an HTML page,
  # so it's easier to display them in an iframe.
  #
  def create_image_component
    return unless image?
    path = ebook.component_path(self) + ".xhtml"
    ebook.create_subfolders_for_path path
    File.open(path, 'w')  do |f|
      raw = File.read(ebook.unzipped_component_path(self))
      base64 = Base64.strict_encode64(raw)
      f.write "<html><body><img src='data:#{media_type};base64,#{base64}'></body></html>"
    end
    self.media_type = 'application/xhtml+xml'
    self.src = "#{src}.xhtml"
    self.properties["nomargin"] = true
  end
end
