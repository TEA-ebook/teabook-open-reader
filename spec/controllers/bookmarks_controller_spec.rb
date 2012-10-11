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

describe BookmarksController do

  let(:book) { Fabricate(:ebook_epub) }
  let(:bookmark) { Fabricate(:bookmark, book: book) }
  let(:user) { Fabricate(:user, books: [book]) }

  before :each do
    sign_in user
  end

  it "should have a current_user" do
    subject.current_user.should_not be_nil
  end

  # This should return the minimal set of attributes required to create a valid
  # Bookmark. As you add validations to Bookmark, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {book_id: book.to_param, component_name: book.components.first.src}
  end

  def create_a_bookmark!
    book.update_attributes!(bookmarks: [bookmark])
  end


  describe "GET index" do
    before { create_a_bookmark! }

    it "assigns all bookmarks as @bookmarks" do
      get :index, {book_id: book.to_param}
      assigns(:bookmarks).should eq([bookmark])
    end
  end

  describe "GET show" do
    before { create_a_bookmark! }

    it "assigns the requested bookmark as @bookmark" do
      get :show, {:id => bookmark.to_param, book_id: book.to_param}
      assigns(:bookmark).should eq(bookmark)
    end
  end

  describe "GET new" do
    it "assigns a new bookmark as @bookmark" do
      get :new, {book_id: book.to_param}
      assigns(:bookmark).should be_a_new(Bookmark)
    end
  end

  describe "GET edit" do
    before { create_a_bookmark! }

    it "assigns the requested bookmark as @bookmark" do
      get :edit, {:id => bookmark.to_param, book_id: book.to_param}
      assigns(:bookmark).should eq(bookmark)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Bookmark" do
        expect {
          post :create, {book_id: book.to_param, bookmark: valid_attributes}
        }.to change(Bookmark, :count).by(1)
      end

      it "assigns a newly created bookmark as @bookmark" do
        post :create, {book_id: book.to_param, bookmark: valid_attributes}
        assigns(:bookmark).should be_a(Bookmark)
        assigns(:bookmark).should be_persisted
      end

      it "redirects to the created bookmark" do
        post :create, {book_id: book.to_param, bookmark: valid_attributes}
        response.should redirect_to(book_bookmark_url(book, Bookmark.last))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved bookmark as @bookmark" do
        # Trigger the behavior that occurs when invalid params are submitted
        Bookmark.any_instance.stub(:save).and_return(false)
        post :create, {book_id: book.to_param, bookmark: {}}
        assigns(:bookmark).should be_a_new(Bookmark)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Bookmark.any_instance.stub(:save).and_return(false)
        post :create, {book_id: book.to_param, bookmark: {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    before { create_a_bookmark! }

    describe "with valid params" do
      it "updates the requested bookmark" do
        # Assuming there are no other bookmarks in the database, this
        # specifies that the Bookmark created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Bookmark.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => bookmark.to_param, book_id: book.to_param, bookmark: {'these' => 'params'}}
      end

      it "assigns the requested bookmark as @bookmark" do
        put :update, {:id => bookmark.to_param, book_id: book.to_param, bookmark: valid_attributes}
        assigns(:bookmark).should eq(bookmark)
      end

      it "redirects to the bookmark" do
        put :update, {:id => bookmark.to_param, book_id: book.to_param, bookmark: valid_attributes}
        response.should redirect_to(book_bookmark_path(book))
      end
    end

    describe "with invalid params" do
      it "assigns the bookmark as @bookmark" do
        # Trigger the behavior that occurs when invalid params are submitted
        Bookmark.any_instance.stub(:save).and_return(false)
        put :update, {:id => bookmark.to_param, book_id: book.to_param, bookmark: {}}
        assigns(:bookmark).should eq(bookmark)
      end

      it "re-renders the 'edit' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Bookmark.any_instance.stub(:save).and_return(false)
        put :update, {:id => bookmark.to_param, book_id: book.to_param, bookmark: {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    before { create_a_bookmark! }

    it "destroys the requested bookmark" do
      expect {
        delete :destroy, {:id => bookmark.to_param, book_id: book.to_param}
      }.to change(Bookmark, :count).by(-1)
    end

    it "redirects to the bookmarks list" do
      delete :destroy, {:id => bookmark.to_param, book_id: book.to_param}
      response.should redirect_to(book_bookmarks_path(book))
    end
  end

end
