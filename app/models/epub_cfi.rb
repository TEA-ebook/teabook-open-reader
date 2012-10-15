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


class EpubCfi

  def initialize(epub)
    @epub = epub
  end

  def path(xpath, component_src)
    return if xpath.empty?

    head = cfi_base(href: component_src)
    component_html = get_document(component_text(component_src))

    tail = cfi_path(xpath, component_html)

    "#{head}#{tail}"
  end

  def range(component_src, start_xpath, start_offset, end_xpath, end_offset)
    return if [component_src, start_xpath, start_offset, end_xpath, end_offset].any?(&:blank?)

    base = cfi_base(href: component_src)
    component_html = get_document(component_text(component_src))

    start_subpath = '%s:%s' % [ cfi_path(start_xpath, component_html), start_offset ]
    end_subpath = '%s:%s' % [ cfi_path(end_xpath, component_html), end_offset ]

    "#{base}#{extract_longest_common_path(start_subpath, end_subpath).join(',')}"
  end

  protected

  def get_document(component_text)
    get_html_node('//html', component_text)
  end

  def get_html_node(xpath, document)
    Nokogiri::HTML(document).at_xpath(xpath)
  end

  def cfi_base(criteria)
    itemref = if criteria[:idref]
                itemref_with_idref(criteria[:idref])
              elsif criteria[:href]
                itemref_with_href(criteria[:href])
              else
                raise ArgumentError, "You must provide either an idref or a href!"
              end

    return unless itemref

    cfi_path(itemref, opf.at_xpath('//package')) + '!'
  end

  def cfi_path(node_or_xpath, reference_element)
    return unless reference_element

    element = case node_or_xpath
                when String
                  reference_element.at_xpath(node_or_xpath)
                when Nokogiri::XML::Node
                  node_or_xpath
                else
                  raise ArgumentError, "Unknown input #{node_or_xpath}"
              end

    return unless element

    current_node = element
    path = ["/#{cfi_index_for_node(current_node)}"]

    while current_node.path != reference_element.path && current_node.respond_to?(:parent) && current_node = current_node.parent
      if path_element = cfi_index_for_node(current_node)
        path.unshift "/#{path_element}"
      end
    end

    path[1..-1].join
  end


  # Nokogirified version of the package document
  #
  # @return [Nokogiri::XML::Document]
  def opf
    return @opf if @opf

    @opf ||= Nokogiri::XML(package_document)
    @opf.remove_namespaces!
    @opf
  end

  def itemref_with_href(href)
    if item = item_with_href(href)
      opf.at_xpath(%Q{//spine/itemref[@idref="#{item.attribute('id')}"]})
    end
  end

  def itemref_with_idref(idref)
    opf.at_xpath(%Q{//itemref[@idref="#{idref}"]})
  end

  def item_with_href(href)
    opf.at_xpath(%Q{//manifest/item[@href="#{href}"]})
  end

  def package_document
    @epub.package_document
  end

  def component_text(component_src)
    @epub.component_with_src(component_src).content
  end

  def cfi_index_for_node(node)
    return unless node.respond_to? :parent
    count_offset = node.element? ? 2 : 1

    index = (node.parent.children.   # among all of node's parent children
             select {|e| e.node_type == node.node_type }. # that are like the current node
             find_index {|e| e.path == node.path } * 2) + count_offset # find the node index,
                                             # on an even or odd-numbered scale,
                                             # according to the node type

    index = index.to_s
    index << "[#{node.attribute('id')}]" if node.attribute('id')
    index
  end

  def extract_longest_common_path(start_xpath, end_xpath)
    start_array = start_xpath.scan(%r{/[^/]+})
    end_array   = end_xpath.scan(%r{/[^/]+})

    index = start_array.each.with_index.find_index {|element, i| element != end_array[i] }

    common_path = start_array[0..index-1]
    start_path  = start_array[index..-1]
    end_path    = end_array[index..-1]

    [common_path, start_path, end_path ].map(&:join)
  end

end
