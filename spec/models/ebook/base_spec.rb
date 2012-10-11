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

describe Ebook::Base do
  let(:ebook) { Fabricate(:ebook) }
  let(:user) { Fabricate(:user) }
  let(:publications_hash) { JSON.parse(File.read('spec/fixtures/api/publications.json')) }

  before :each do
    # Mock remote cover url
    FakeWeb.register_uri(:get, 'http://example.com/cover.jpg',
      body: File.read('public/fallback/cover/library_default.png')
    )
  end

  describe 'fields' do
    it { should have_field(:api_id) }
    it { should have_field(:bookstore_id) }
    it { should have_field(:format) }
    it { should have_field(:title) }
    it { should have_field(:subtitle) }
    it { should have_field(:language) }
    it { should have_field(:authors).of_type(Array) }
    it { should have_field(:publisher).of_type(Hash) }
    it { should have_field(:direction) }
    it { should have_field(:license) }
  end

  describe 'relations' do
    it {
      should reference_many(:bookmarks).with_dependent(:destroy).
        as_inverse_of(:book)
    }
    it {
      should have_and_belong_to_many(:users).as_inverse_of(:books)
    }
  end

  describe 'initial state' do

    it 'should set state to created if no file given' do
      e = Fabricate(:ebook, file: nil)
      e.save!
      e.created?.should be_true
    end

    it 'should set state to created if file given' do
      e = Fabricate(:ebook)
      e.save!
      e.uploaded?.should be_true
    end

  end

  describe 'create from api' do

    it 'should create Ebook::Epub if format equal epub' do
      expect {
        Ebook::Base.create_from_api({format: 'epub', id: '42', title: 'Lorem Ipsum'}, user)
      }.to change(Ebook::Epub, :count).by(1)
    end

    it 'should update Ebook::Epub if api_id is already present in db' do
      expect {
        Ebook::Base.create_from_api({format: 'epub', id: '42', title: 'Title 1'}, user)
        Ebook::Epub.where(api_id: '42').one.title.should == 'Title 1'
        Ebook::Base.create_from_api({format: 'epub', id: '42', title: 'Title 2'}, user)
        Ebook::Epub.where(api_id: '42').one.title.should == 'Title 2'
      }.to change(Ebook::Epub, :count).by(1)
    end

    it 'should create nothing (for now) if format not equal epub' do
      expect {
        Ebook::Base.create_from_api({format: 'pdf', id: '42'}, user)
      }.to_not change(Ebook::Epub, :count)
    end

    it 'should add user to user_ids array' do
      e = Ebook::Base.create_from_api publications_hash['results'].first, user
      e.user_ids.should include user.id
    end

    it 'should import fields from api' do
      e = Ebook::Base.create_from_api publications_hash['results'].first, user
      e.reload
      e.api_id.should == '123'
      e.bookstore_id.should == "fake"
      e.title.should == "Ebook 1"
      e.subtitle.should == "Ebook 1 subtitle"
      e.authors.should == [
        {
          "author_name" => "William Shakespeare",
          "role" => "role 1", "main" => true
        },
        {
          "author_name" => "Honoré de Balzac",
          "role" => "role 2", "main" => false
        }
      ]
      e.format.should == "epub"
      e.language.should == "fr"
      e.license.should == "none"
      e.publisher.should == {
        "publisher_name" => "Publisher name",
        "collection" => "Collection 1",
        "publication_date" => "2011-07-30T01:00:00+01:00"
      }
      e.descriptions.should == [
        {
          "type" => "summary",
          "content" => "Lorem ipsum dolor sit amet, consectetur adipisicing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua"
        }
      ]
      e.remote_cover_url.should == 'http://example.com/cover.jpg'
      e.cover.should_not be_nil
    end

    it 'should update number of bookmarks on user' do
      e = Ebook::Base.create_from_api publications_hash['results'].first, user
      user.number_of_bookmarks[e.id.to_s].should == "42"
    end

    it 'should create/update purchases on user' do
      e = Ebook::Base.create_from_api publications_hash['results'].first, user
      user.purchases[e.id.to_s].should == {
        "type" => "bought",
        "date" => "2011-07-30T01:00:00+01:00"
      }
    end

    it 'should create/update readings for user' do
      expect {
        Ebook::Base.create_from_api publications_hash['results'].first, user
      }.to change { ReadingPosition.count }
    end

  end

  describe '#download!' do
    let(:ebook) { Fabricate(:ebook_epub_api) }

    it 'should know is download url' do
      ebook.tea_download_url.should == "/publications/#{ebook.api_id}/download"
    end

    it 'should download file from API' do
      epub_content = File.read('spec/fixtures/api/example.epub')
      response = Typhoeus::Response.new(:code => 200, :body => epub_content)
      Typhoeus::Hydra.hydra.stub(:get, "#{Gaston.api.host}#{ebook.tea_download_url}").and_return(response)
      ebook.update_attribute(:state, 'created')
      ebook.download! 'acookie'
      File.read(ebook.file.current_path).should == epub_content
    end
  end

end
