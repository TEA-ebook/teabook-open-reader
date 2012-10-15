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

describe Ebook::EpubsController do
  let(:user) {
    user = Fabricate :user
    # TODO specific fabricator
    user.update_attribute(:accounts, {tea: {email: 'test@example.com'}})
    user
  }
  let(:bookseller) { Fabricate :bookseller }
  let(:ebook) { Fabricate :ebook_epub}
  let(:ebooks) { [ebook] }

  before :each do
    sign_in user
  end

  describe 'GET #index' do

    describe 'with html format' do

      it 'should render template index' do
        get :index
        response.status.should be 200
        response.should render_template :index
      end

      it 'should schedule ebook import for each active bookstore sessions if last import is older than 5 minutes old' do
        user.update_attribute :last_import_at, {'tea' => (Time.now - 6.minutes)}
        session[:tea_sessions] = {'tea' => {
          'id' => 'acookie', 'expire' => (Time.now + 1.day).to_i
        }}
        controller.current_user.should_receive(:enqueue_import_books).with('acookie', 'tea').and_return(true)
        get :index
      end

      it 'should not schedule ebook import if last import is not older than 5 minutes old' do
        user.update_attribute :last_import_at, {'tea' => (Time.now - 4.minutes)}
        session[:tea_sessions] = {'tea' => {
          'id' => 'acookie', 'expire' => (Time.now + 1.day).to_i
        }}
        controller.current_user.should_not_receive(:enqueue_import_books)
        get :index
      end

    end

    describe 'with json format' do

      describe 'on generic website' do
        before :each do
          controller.stub(:current_bookseller).and_return(nil)
          controller.current_user.stub_chain(:books).and_return(ebooks)
        end

        it 'should render a json representation of all user ebooks' do
          get :index, format: :json
          assigns(:ebooks).should == ebooks
          response.body.should == ebooks.as_json(reading_position: true).to_json()
        end

        it 'should add user informations on ebooks representation' do
          pending
        end

      end

      describe 'on bookseller specific website' do
        before :each do
          controller.stub(:current_bookseller).and_return(bookseller)
          controller.current_user.stub_chain(:books, :bookstore).and_return(ebooks)
        end

        it 'should render a json representation of all user ebooks' do
          get :index, format: :json
          assigns(:ebooks).should == ebooks
          response.body.should == ebooks.as_json(reading_position: true).to_json()
        end

      end

    end

  end

  describe 'GET #show' do

    describe 'with json format' do

      it 'should render a json representation of ebook' do
        controller.current_user.stub_chain(:books, :find).and_return(ebook)
        get :show, id: 42, format: :json
        assigns(:ebook).should == ebook
        response.body.should == ebook.to_json(components: true, chapters: true)
      end

    end

  end

  describe 'GET #new' do

    describe 'with html format' do
      before :each do
        get :new, id: 42, format: :html
      end

      it 'should render template :new' do
        response.should render_template :new
      end

      it 'should assign a new ebook' do
        assigns(:ebook).persisted?.should be_false
      end

    end

  end

  describe 'POST #create' do

    describe 'with valid params' do

      before :each do
        # Must be created before for assertion on new
        ebook
        Ebook::Epub.should_receive(:new).with('these' => 'params', 'source' => 'upload', 'format' => 'epub').and_return(ebook)
        ebook.should_receive(:save).and_return(true)
        post :create, ebook_epub: {'these' => 'params'}
      end

      it 'should redirect to ebook_epubs_url' do
        response.should redirect_to ebook_epubs_url
      end

      it 'should add current user to ebooks users' do
        assigns(:ebook).users.should include user
      end

      it 'should create purchase on user' do
        pending
      end

    end

    describe 'with invalid params' do

      before :each do
        # Must be created before for assertion on new
        ebook
        Ebook::Epub.should_receive(:new).with('these' => 'params', 'source' => 'upload', 'format' => 'epub').and_return(ebook)
        ebook.should_receive(:save).and_return(false)
        post :create, ebook_epub: {'these' => 'params'}
      end

      it 'should render template new' do
        response.should render_template :new
      end

      it 'should add current user to ebooks users' do
        assigns(:ebook).users.should include user
      end

      it 'should create not purchase on user' do
        pending
      end

    end

  end

  describe 'GET #edit' do

    describe 'with html format' do
      before :each do
        controller.current_user.stub_chain(:books, :find).and_return(ebook)
        get :edit, id: 42, format: :html
      end

      it 'should render template :edit' do
        response.should render_template :edit
      end

      it 'should assign ebook' do
        assigns(:ebook).should == ebook
      end

    end

  end

  describe 'PUT #update' do

    describe 'with valid params' do

      before :each do
        controller.current_user.stub_chain(:books, :find).and_return(ebook)
        ebook.should_receive(:update_attributes).with('these' => 'params').and_return(true)
        put :update, id: 42, ebook_epub: {'these' => 'params'}
      end

      it 'should redirect to ebook_epubs_url' do
        response.should redirect_to ebook_epubs_url
      end

    end

    describe 'with invalid params' do

      before :each do
        controller.current_user.stub_chain(:books, :find).and_return(ebook)
        ebook.should_receive(:update_attributes).with('these' => 'params').and_return(false)
        put :update, id: 42, ebook_epub: {'these' => 'params'}
      end

      it 'should render template edit' do
        response.should render_template :edit
      end

    end

  end

  describe 'DELETE #destroy' do

    describe 'with html format' do
      before :each do
        controller.current_user.stub_chain(:books, :find).and_return(ebook)
        delete :destroy, id: 42, format: :html
      end

      it 'should redirect to ebook_epubs_url' do
        response.should redirect_to ebook_epubs_url
      end

      it 'should assign ebook' do
        assigns(:ebook).should == ebook
      end

    end

  end

end
