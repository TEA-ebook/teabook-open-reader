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


require "shellwords"


class Ebook::Epub < Ebook::Base
  field :properties,        type: Hash, default: {}
  field :cover_properties,  type: Hash, default: {}
  field :epub_version,      type: Float

  embeds_many :components, class_name: 'Ebook::Epub::Component'
  references_many :chapters, class_name: 'Ebook::Epub::Chapter',
    inverse_of: :ebook, dependent: :destroy

  before_save :missing_title
  after_initialize :prepare_hash


  def self.find_or_initialize_from_api(api_id)
    find_or_initialize_by(api_id: api_id, source: 'api')
  end

  # Does this ebook come from API?
  #
  def from_api?
    source == 'api'
  end

  # Was this ebook uploaded by a user?
  #
  def uploaded?
    source == 'upload'
  end

  # Can we assume that this eook is safe?
  #
  def safe?
    Gaston.security.allow_js
  end

  def as_json(options = {})
    options.merge!(
      methods: ['converted?'],
      include: {},
      except: []
    )
    if options.delete(:chapters)
      options[:include][:chapters] = {only: [:title, :src]}
    else
      options[:except] << :chapters
    end
    if options.delete(:components)
      options[:include][:components] = {only: [:_id, :src, :properties]}
    else
      options[:except] << :components
    end
    if options[:reading_position]
      options[:include][:reading_position] = {}
    else
      options[:except] << :reading_position
    end
    super(options)
  end

  def component_with_src(file_name)
    components.detect {|component| component.src == file_name }
  end

  # Use HashWithIndifferentAccess
  #
  def prepare_hash
    self.properties = self.properties.with_indifferent_access if properties.present?
    self.cover_properties = self.cover_properties.with_indifferent_access if cover_properties.present?
  end

  # Get title from epub if not given in TEA metas
  # Filename is used as a fallback
  def missing_title
    # If a file is uploaded
    if file.present?
      # Use the file basename if not title given
      self.title = File.basename(file.current_path) unless title.present?
      # If properties contains title, replace filename by this title
      # but don't replace title from TEA meta
      if self.title == File.basename(file.current_path) &&
        properties.present? && properties[:title].present?
        self.title = properties[:title]
      end
    end
  end

  # Extract informations from epub (properties, chapters, cover, components)
  #
  def extract
    begin
      extracting
      # Store Ebook version
      self.epub_version = book.version
      self.direction = book.direction

      # Store Ebook properties
      self.properties = book.properties.inject({}){|hash, property|
        if property.key.present?
          hash[property.key] = property.value
        end
        hash
      }.with_indifferent_access

      # Store Ebook cover
      self.cover_properties = {
        media_type: book.cover.media_type,
        src: book.cover.src,
        attributes: book.cover.attributes
      }.with_indifferent_access if book.cover.present?

      # Store Ebook Components
      self.components.destroy_all
      book.components.each do |c|
        self.components.create!(
          properties: c.attributes,
          media_type: c.media_type,
          src: c.src
        )
      end

      # Store Ebook Chapters
      self.chapters.destroy_all
      book.chapters.each do |c|
        self.chapters << Ebook::Epub::Chapter.create_chapter(self, c)
      end

      # if this ebook was uploaded
      if uploaded?
        extract_cover
        extract_metas
      end

      save!
      extracted
    rescue => e
      extract_error
      raise e
    end
  end

  def book
    unzip unless unzipped?
    @book_cache ||= Peregrin::Epub.read(file.current_path).to_book
  end

  # Return the base directory url for this ebook
  #
  # @return String
  def base_dir_url
    File.dirname(file_url)
  end

  # Extracted directory path
  #
  # @return String
  def unzip_dir_path
    File.join(base_dir_path, 'extracted')
  end

  # Return the opf file path
  #
  # @return String
  def opf_path
    File.join(unzip_dir_path, metas['full-path'])
  end

  # Content of the Epub's package document
  #
  # @return [String]
  def package_document
    @package_document ||= File.read(opf_path)
  end

  # Epub::CFI handler for the current document
  #
  # @return [EpubCfi]
  def cfi
    @cfi ||= EpubCfi.new(self)
  end

  # Return the html directory path
  #
  # @return String
  def html_dir_path
    File.join(base_dir_path, 'html')
  end

  # Return the html directory url
  #
  # @return String
  def html_dir_url
    File.join(base_dir_url, 'html')
  end

  # Return the js file path (book data)
  #
  # @return String
  def js_file_path
    File.join(html_dir_path, "book_data.js")
  end

  # Return the js file url (book data)
  #
  # @return String
  def js_file_url
    File.join(html_dir_url, "book_data.js")
  end

  # Return the component/resource path
  #
  # @return String
  def component_path(component)
    File.join(html_dir_path, component.src)
  end

  # Return the unzipped component/resource path
  #
  # @return String
  def unzipped_component_path(component)
    File.join(File.dirname(opf_path), component.src)
  end

  # Return the resource url
  #
  # @return String
  def resource_url(resource)
    File.join(html_dir_url, resource.src)
  end

  # Unzip epub to its own folder
  #
  # @return Boolean
  #
  # FIXME raise an exception if file is not present
  def unzip
    FileUtils.mkdir_p unzip_dir_path
    Zip::Archive.open(file.current_path).each do |entry|
      if !entry.directory?
        file_path = File.dirname(entry.name)
        if file_path != "."
          FileUtils.mkdir_p "#{unzip_dir_path}/#{file_path}"
        end
        open("#{unzip_dir_path}/#{entry.name}", 'wb') do |f|
          f << entry.read
        end
      end
    end
  end

  # Is this epub is unzipped ?
  #
  # @return Boolean
  def unzipped?
    File.exists?(
      File.join(unzip_dir_path, 'META-INF/container.xml')
    )
  end

  # Extract epub meta from META-INF/container.xml
  #
  # @return Hash
  def metas
    unzip unless unzipped?
    Nokogiri::HTML(
      File.read(File.join(unzip_dir_path, 'META-INF/container.xml'))
    ).css('rootfile').first.attributes.inject({}){|hash, attr|
      hash[attr[0]] = attr[1].value
      hash
    }
  end

  # Export epub to static html
  def convert_to_html
    begin
      converting
      unzip unless unzipped?
      # Create html folder
      Dir.mkdir html_dir_path unless File.exists?(html_dir_path)

      # Copy all items to html folder
      copy_to_html_folder

      # Prepare components
      components.each do |c|
        c.extract_dimensions
        c.create_image_component
      end

      converted
    rescue => e
      convert_error
      raise e
    end
  end

  # Extract cover from epub content
  #
  def extract_cover
    return unless uploaded?
    # Copy cover (will be converted by carrierwave)
    if self.cover_properties.present?
      self.cover = File.open(
        File.join(File.dirname(opf_path), self.cover_properties['src'])
      )
      if self.valid?
        self.save
      else
        self.cover = nil
      end
    end
  end

  # Extract metas from epub content
  #
  def extract_metas
    extract_authors
    extract_publisher
    extract_language
    extract_description
  end

  def extract_authors
    if author = (self.properties['creator']||self.properties['dcterms:creator'])
      self.authors = [{author_name: author, main: true}]
    end
  end

  def extract_publisher
    if publisher = (self.properties['publisher']||self.properties['dcterms:publisher'])
      self.publisher = {publisher_name: publisher}
    end
  end

  def extract_language
    if language = self.properties['language']
      self.language = language
    end
  end

  def extract_description
    if description = self.properties['description']
      self.descriptions = [{type: 'summary', content: description}]
    end
  end

  # Copy all items to html folder
  # Also fix assets path in texts
  #
  def copy_to_html_folder
    copy_resources
    copy_components
  end

  # Create required subfolders for a given path
  #
  def create_subfolders_for_path(path)
    unless Dir.exists?(File.dirname(path))
      FileUtils.mkdir_p File.dirname(path)
      File.chmod(0755, File.dirname(path))
    end
  end

  # Copy all resources to html folder
  #
  def copy_resources
    book.resources.each do |resource|
      path = component_path(resource)
      create_subfolders_for_path(path)
      FileUtils.cp unzipped_component_path(resource), path
      File.chmod(0644, path)
      optimize_resource path
    end
  end

  # Copy all components to html folder
  #
  def copy_components
    book.components.each do |component|
      path = component_path(component)
      create_subfolders_for_path(path)
      # If component is an image :
      # * copy with same encoding
      # * nothing to fix in its content
      if component.media_type =~ Component::IMG_REGEXP
        File.open(path, "w:#{component.contents.encoding}") {|f|
          f.write component.contents
        }
      # If component is not an image :
      # * copy as utf-8
      # * fix its content
      else
        File.open(path, 'w') {|f|
          f.write fix_content(component)
        }
      end
      File.chmod(0644, path)
    end
  end

  # Try to reduce the size of resources
  #
  def optimize_resource(path)
    case File.extname(path).downcase
    when ".png"
      system("optipng -o5 #{path.shellescape}")
    when ".jpg", ".jpeg"
      system("jpegoptim -v -t #{path.shellescape}")
    end
  end

  # Fix component content
  # * Apply fix asset paths
  # * Parse and reformat html with Nokogiri
  # * Escape javascript if we can't assume the ebook is safe
  #
  # @return String
  def fix_content(component)
    raw = fix_resource_urls(component)
    return fix_svg_content(raw) if svg_component?(component)

    raw.gsub!(/<\?xml[^>]*\?>/, '')
    output = Loofah.document(raw)
    output.scrub!(:prune) unless safe?
    # Prevent double xmlns added by Nokogiri
    # https://github.com/tenderlove/nokogiri/issues/339
    output.xpath('//html[@xmlns]').each {|elem| elem.delete('xmlns') }
    fix_internal_link_hrefs!(component, output)
    prepare_assets(output).to_html
  end

  def fix_svg_content(raw)
    output = Nokogiri::XML(raw)
    output.remove_namespaces!
    book.resources.each do |resource|
      case resource.media_type
      when /^image\//
        base64 = Base64.strict_encode64(
          File.read(component_path(resource))
        )
        output.css("image").each do |img|
          if img['href'] == resource_url(resource)
            img['xlink:href'] = "data:#{resource.media_type};base64,#{base64}"
          end
        end
      end
    end
    output.to_xml
  end

  # Embed images in content
  #
  # @param node Nokogiri::HTML::Document
  #
  # @return Nokogiri::HTML::Document
  # TODO specs
  def prepare_assets(node)
    book.resources.each do |resource|
      case resource.media_type
      when /^image\//
        base64 = Base64.strict_encode64(
          File.read(component_path(resource))
        )
        node.css("img[@src='#{resource_url(resource)}']").each do |img|
          img['src'] = "data:#{resource.media_type};base64,#{base64}"
        end

        # Embed SVG images
        node.xpath("//image").each do |img|
          if img['xlink:href'] == resource_url(resource)
            img['xlink:href'] = "data:#{resource.media_type};base64,#{base64}"
          end
        end

      when /^text\/css$/
        # FIXME embed alternate stylesheets ?
        node.xpath("//link[@href='#{resource_url(resource)}' and @rel='stylesheet']").each do |link|
          css_content = fix_encoding(File.read(component_path(resource)))
          css_content = flatten_css(css_content)
          css_content = css_content.gsub(/\r/, '').gsub(/oeb[^;}]+;/, '').gsub(/\s+$/, "\n")
          style = Nokogiri::XML::Node.new "style", node
          style['type'] = 'text/css'
          style.content = css_content
          link.replace(style)
        end
      when /^text\/javascript$/
        node.xpath("//script[@src='#{resource_url(resource)}']").each do |tag|
          script_content = fix_encoding(File.read(component_path(resource)))
          script = Nokogiri::XML::Node.new "script", node
          script['type'] = 'text/javascript'
          script.content = script_content
          tag.replace(script)
        end
      end
    end
    node
  end

  # Flatten css :
  # * inject content of external import
  # * embed font
  # * embed images
  #
  # @params String
  #
  # @return String
  # TODO specs
  def flatten_css(css)
    css = fix_resource_urls(css)
    # Replace @import
    css.gsub!(/^@import (url\()?['|"](.*)['|"](\))?;$/){|match|
      "/* File: #{$2}*/\n" +
        flatten_css(fix_encoding(File.read(File.join(Rails.root, $2))))
    }
    # Encode known images and fonts
    book.resources.each do |resource|
      case resource.media_type
      when /^image\//, /font/
        base64 = Base64.strict_encode64(
          File.read(component_path(resource))
        )
        css.gsub! /url\(['|"]?#{resource_url(resource)}['|"]?\)/,
          "url(\"data:#{resource.media_type};base64,#{base64}\")"
      end
    end
    css
  end

  # Some resources path may have a relative path like ../Images
  # Because our generated html file is not in the same directory
  # than unzipped html content, we must fix them in order to use
  # a path relative to our html_dir_url
  #
  # @return String
  def fix_resource_urls(text_or_component)
    if text_or_component.is_a? String
      text = text_or_component
    else
      text = text_or_component.contents
      # Get the component path to fix relative path
      component_path = File.dirname(text_or_component.src)
    end
    # Fix resources url in xhtml content
    book.resources.each do |resource|
      # If a component given and is in a subfolder, we check for relative url
      if component_path.present?
        found = text.gsub! /(["'(])(\.\.\/)*#{resource.src.gsub("#{component_path}\/", "")}(["')])/, "\\1#{resource_url(resource)}\\3"
      end
      # If not already found, fix path on given resource url
      text.gsub! /(["'(])(\.\.\/)*#{resource.src}(["')])/, "\\1#{resource_url(resource)}\\3" if found.nil?
    end
    text
  end

  def fix_internal_link_hrefs!(component, document)
    filename = File.basename component_path(component)
    html_dir_pathname = Pathname.new(html_dir_path)
    component_pathname = Pathname.new(component_path(component))
    relative_dirname = component_pathname.relative_path_from(html_dir_pathname).dirname

    document.xpath("//body//a").each do |a|
      href = a['href']
      next if href.blank? or href =~ /^tel:/

      anchor = URI.parse(href)
      next if anchor.absolute? || anchor.path.starts_with?("#{relative_dirname}/")
      anchor.path = filename if anchor.path.blank?

      new_anchor = Nokogiri::XML::Node.new "a", document
      a.attributes.each {|name, attr| new_anchor[name] = attr.value }
      new_anchor['href'] = relative_dirname.join(anchor.to_s).to_s
      new_anchor.content = a.content
      a.replace new_anchor
    end
  end

  # Enqueue epub extraction
  def enqueue_extract_epub
    Resque.enqueue(ExtractEpubWorker, id)
  end

  # Enqueue conversion to html format
  def enqueue_conversion
    Resque.enqueue(EpubToHTMLWorker, id)
  end

  def store_bytesize
    payload  = self.to_json(components: true, chapters: true)
    payload += self.components.to_json(methods: :content)
    self.update_attribute(:bytesize, payload.bytesize)
  end

  # TODO Move to String ?
  def fix_encoding(string)
    unless string.valid_encoding?
      string.force_encoding("ISO-8859-1")
      string = string.encode("UTF-8")
    end
    string
  end

  # Is the component a SVG resource ?
  def svg_component?(component)
    component.media_type =~ Component::SVG_REGEXP
  end

end
