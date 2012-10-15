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


require 'spec_helper'

describe User do

  let(:user) { Fabricate(:user) }
  let(:publications_json) { File.read('spec/fixtures/api/publications.json') }
  let(:tea_session) {
    TeaApi::Session.new(
      id: "42",
      email: "johndoe@tea-ebook.com",
      firstname: "John",
      lastname: "Doe",
      birthdate: "1980-07-30T01:00:00+01:00",
      country: "FR",
      bookstore: "tea",
      session: "42"
    )
  }
  let(:ebook) { Fabricate(:ebook) }
  before :each do
    # Mock remote cover url
    FakeWeb.register_uri(:get, 'http://example.com/cover.jpg',
      body: File.read('public/fallback/cover/library_default.png')
    )
  end

  describe 'fields' do
    it {should have_field(:purchases).of_type(Hash) }
  end

  describe "relations" do
    it { should reference_many(:bookmarks).with_dependent(:destroy) }
    it { should have_and_belong_to_many(:books).of_type(Ebook::Base).with_dependent(:nullify) }
  end

  describe 'fetch books from API' do
    before :each do
      user.update_attribute(:accounts, {'tea' => {'id' => '42'}})
    end

    it 'should know its API url' do
      user.tea_library_url('tea').should == "/users/42/publications"
    end

    it 'should create ebooks from api' do
      response = Typhoeus::Response.new(:code => 200, :body => publications_json)
      Typhoeus::Hydra.hydra.stub(:get, "#{Gaston.api.host}#{user.tea_library_url('tea')}").and_return(response)
      user.update_attribute(:last_import_at, {})
      expect{
        user.import_books! 'acookie', 'tea'
      }.to change(Ebook::Epub, :count).by(2)
      user.last_import_at['tea'].should_not be_nil
    end

  end

  describe 'find_or_create_from_tea_session' do

    it 'should store all tea_session attributes in User.acounts hash' do
      u = User.find_or_create_from_tea_session(tea_session)
      u.accounts[tea_session.bookstore].should == tea_session.to_user_account
    end

    it 'should not create a user twice' do
      expect{
        u = User.find_or_create_from_tea_session(tea_session)
        u = User.find_or_create_from_tea_session(tea_session)
      }.to change(User, :count).by(1)
    end

    it 'should update account if tea_session has changed' do
      u = User.find_or_create_from_tea_session(tea_session)
      u.accounts[tea_session.bookstore].should == tea_session.to_user_account
      tea_session.firstname = "Hello World"
      u = User.find_or_create_from_tea_session(tea_session)
      u.accounts[tea_session.bookstore][:firstname].should == "Hello World"
    end

  end

  describe 'create_uploaded_purchase' do

    it 'should create a purchase for the given book on user with type user_uploaded' do
      user.create_uploaded_purchase! ebook
      user.reload
      user.purchases[ebook.id.to_s].should_not be_nil
      user.purchases[ebook.id.to_s]['type'].should == 'user_uploaded'
    end
  end

end
