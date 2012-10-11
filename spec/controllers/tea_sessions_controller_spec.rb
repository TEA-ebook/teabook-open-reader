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

describe TeaSessionsController do

  let(:bookseller) { Fabricate(:bookseller) }
  let(:user) { Fabricate(:user) }

  describe 'GET #new' do

    describe 'on a bookstore sub domain' do
      before :each do
        @controller.stub!(:current_bookseller).and_return(bookseller)
        get :new
      end

      it 'should render template :new' do
        response.status.should be 200
        response.should render_template :new
      end

      it 'should assign bookstore to tea_session' do
        assigns(:tea_session).bookstore.should == bookseller.bookstore_id
      end
    end

    describe 'on a generic domain' do
      before :each do
        @controller.stub!(:current_bookseller).and_return(nil)
        get :new
      end

      it 'should render template :new' do
        response.status.should be 200
        response.should render_template :new
      end

      it 'should assign nil to bookstore tea_session attribute' do
        assigns(:tea_session).bookstore.should be_nil
      end
    end

  end

  describe 'POST #create' do
    let(:api_session) { mock_tea_api_session }

    before :each do
      TeaApi::Session.should_receive(:new).with({'foo' => 'bar'}).and_return(api_session)
    end

    describe 'with valid params' do

      before :each do
        api_session.should_receive(:save).and_return(true)
        User.should_receive(:find_or_create_from_tea_session).with(api_session).and_return(user)
        user.should_receive(:enqueue_import_books).and_return(true)
        post :create, tea_api_session: {'foo' => 'bar'}
      end

      it 'should redirect to root_path' do
        response.status.should be 302
        response.should redirect_to ebook_epubs_path
      end

      it 'should set session[:tea_sessions][:bookstore]' do
        session[:tea_sessions][mock_tea_api_session.bookstore].should == mock_tea_api_session.session
      end

    end

    describe 'with invalid params' do

      before :each do
        api_session.should_receive(:save).and_return(false)
        User.should_not_receive(:find_or_create_from_tea_session)
        post :create, tea_api_session: {'foo' => 'bar'}
      end

      it 'should render template :new to root_path' do
        response.status.should be 200
        response.should render_template :new
      end

      it 'should set session[:tea_sessions][:bookstore]' do
        session[:tea_sessions][mock_tea_api_session.bookstore].should be_nil
      end

    end

  end

  describe 'DELETE #destroy' do
    before :each do
      sign_in user
    end

    it 'should destroy session for given bookstore' do
      session[:tea_sessions] = {'tea' => '42'}
      delete :destroy, id: 'tea'
      session[:tea_sessions].should be_nil
      response.should redirect_to root_path
    end

  end

end
