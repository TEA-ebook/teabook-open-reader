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
require 'spec_helper'

describe Ebook::Epub do
  before :each do
    ResqueSpec.reset!
  end

  describe 'fields' do
    it { should have_field(:properties).of_type(Hash) }
    it { should have_field(:cover_properties).of_type(Hash) }
  end

  describe 'relations' do
    it {
      should embed_many(:components).of_type(Ebook::Epub::Component)
    }
    it {
      should reference_many(:chapters).of_type(Ebook::Epub::Chapter)
        .with_dependent(:destroy).as_inverse_of(:ebook)
    }
  end

  let(:ebook) { Fabricate(:ebook_epub) }
  let(:ebook_upload) { Fabricate(:ebook_epub_upload) }

  it 'should enqueue ExtractEpubWorker after create if file given' do
    e = Fabricate(:ebook_epub)
    ExtractEpubWorker.should have_queued(e.id).in(:extract_epub)
  end

  it 'should not enqueue ExtractEpubWorker after create if file is not given' do
    e = Fabricate(:ebook_epub, file: nil)
    ExtractEpubWorker.should_not have_queued(e.id).in(:extract_epub)
  end

  it 'should enqueue_conversion' do
    ebook.enqueue_conversion
    EpubToHTMLWorker.should have_queued(ebook.id).in(:epub_to_html)
  end

  it 'should unzip epub' do
    ebook.unzip.should be_true
    ebook.unzipped?.should be_true
  end

  it 'should extract epub meta' do
    ebook.metas.should == {
      'full-path'  => 'Ops/content.opf',
      'media-type' => 'application/oebps-package+xml'
    }
  end

  describe 'paths and url' do

    it 'should return base dir path' do
      ebook.base_dir_path.should == File.dirname(ebook.file.current_path)
    end

    it 'should return base dir url' do
      ebook.base_dir_url.should == File.dirname(ebook.file_url)
    end

    it 'should return unzip dir path' do
      ebook.unzip_dir_path.should == File.join(ebook.base_dir_path, 'extracted')
    end

    it 'should return html dir path' do
      ebook.html_dir_path.should == File.join(ebook.base_dir_path, 'html')
    end

    it 'should return html dir url' do
      ebook.html_dir_url.should == File.join(ebook.base_dir_url, 'html')
    end

    it 'should return component path' do
      ebook.component_path(ebook.book.components.first).should == File.join(ebook.html_dir_path, '1.html')
    end

    it 'should return unzipped component path' do
      ebook.unzipped_component_path(ebook.book.components.first).should == File.join(ebook.unzip_dir_path, 'Ops/1.html')
    end

    it 'should return resource url' do
      ebook.resource_url(ebook.book.components.first).should == File.join(ebook.html_dir_url, '1.html')
    end
  end

  it 'should extract properties' do
    ebook.extract
    ebook.properties.should == {
      "title"       => "Dictionnaire des idées reçues",
      "creator"     => "Gustave Flaubert",
      "subject"     => "Romans Classiques",
      "date"        => "2010-06-08",
      "identifier"  => "awp2010-06-08T22:44:46Z",
      "language"    => "fr"
    }
  end

  it 'should extract cover_properties' do
    ebook.extract
    ebook.cover_properties.should == {
      "media_type"  => "image/jpeg",
      "src"         => "images/img1.jpg",
      "attributes"  => {
        "id" => "img1"
      }
    }
  end

  it 'should extract components' do
    ebook.extract
    ebook.components.size.should == 1
    ebook.components.first.properties.should == {:id=>"id1", linear:"yes"}
    ebook.components.first.media_type.should == "application/xhtml+xml"
    ebook.components.first.src.should == "1.html"
  end

  it 'should extract chapters' do
    ebook.extract
    ebook.chapters.size.should == 26
    ebook.chapters.first.title.should == "Page titre"
    ebook.chapters.first.src.should == "1.html"
    ebook.chapters.first.position.should == 1
  end

  it 'should convert epub to html and copy resources/components to same folder' do
    ebook.convert_to_html
    ebook.book.resources.each do |resource|
      File.exists?(File.join(ebook.html_dir_path, resource.src)).should be_true
    end
    ebook.book.components.each do |component|
      File.exists?(File.join(ebook.html_dir_path, component.src)).should be_true
    end
  end

  it 'should fix asset paths in content' do
    resource = Peregrin::Resource.new("../Images/img1.jpg", "image/jpeg")
    ebook.book.should_receive(:resources).and_return([resource])
    ebook.should_receive(:resource_url).with(resource).and_return('Images/img1.jpg')
    ebook.fix_resource_urls('<h1>Hello World</h1><img src="../Images/img1.jpg"/><p>Helo World</p>').should ==
      '<h1>Hello World</h1><img src="Images/img1.jpg"/><p>Helo World</p>'
  end

  it 'should store bytesize after conversion' do
    ebook.extract
    ebook.bytesize.should be_nil
    ebook.convert_to_html
    ebook.bytesize.should_not be_nil
  end

  it 'should extract metas for uploaded ebooks' do
    ebook_upload.extract
    ebook_upload.authors.should == [{author_name: "Gustave Flaubert", main: true}]
    ebook_upload.language.should == 'fr'
    # No other metas in this ebook :/
    ebook_upload.publisher.should == {}
    ebook_upload.descriptions.should == []
  end

end
