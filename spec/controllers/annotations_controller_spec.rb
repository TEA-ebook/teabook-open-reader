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

describe AnnotationsController do

  let(:book) { Fabricate(:ebook_epub) }
  let(:annotation) { Fabricate(:annotation, book: book) }
  let(:user) { Fabricate(:user, books: [book]) }

  before :each do
    sign_in user
  end

  it "should have a current_user" do
    subject.current_user.should_not be_nil
  end

  # This should return the minimal set of attributes required to create a valid
  # Annotation. As you add validations to Annotation, be sure to
  # update the return value of this method accordingly.
  def valid_attributes
    {book_id: book.to_param, component_name: book.components.first.src, note: "blah"}
  end

  def create_an_annotation!
    book.update_attributes!(annotations: [annotation])
  end


  describe "GET index" do
    before { create_an_annotation! }

    it "assigns all annotations as @annotations" do
      get :index, {book_id: book.to_param, format: :json}
      response.body.should == [annotation].to_json
    end

    it "returns a 200 OK HTTP code" do
      get :index, {book_id: book.to_param, format: :json}
      response.status.should == 200
    end
  end

  describe "GET show" do
    before { create_an_annotation! }

    it "assigns the requested annotation as @annotation" do
      get :show, {:id => annotation.to_param, book_id: book.to_param, format: :json}
      assigns(:annotation).should eq(annotation)
    end

    it "returns a 200 OK HTTP code" do
      get :show, {:id => annotation.to_param, book_id: book.to_param, format: :json}
      response.status.should == 200
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Annotation" do
        expect {
          post :create, {book_id: book.to_param, annotation: valid_attributes, format: :json}
        }.to change(Annotation, :count).by(1)
      end

      it "assigns a newly created annotation as @annotation" do
        post :create, {book_id: book.to_param, annotation: valid_attributes, format: :json}
        assigns(:annotation).should be_a(Annotation)
        assigns(:annotation).should be_persisted
      end

      it "answers with a 201 response" do
        post :create, {book_id: book.to_param, annotation: valid_attributes, format: :json}
        response.status.should == 201
      end

    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved annotation as @annotation" do
        post :create, {book_id: book.to_param, annotation: {"note" => ""}, format: :json}
        assigns(:annotation).should be_a_new(Annotation)
      end

      it "returns a 406 HTTP error" do
        post :create, {book_id: book.to_param, annotation: {"note" => ""}, format: :json}
        response.status.should == 422
      end
    end
  end

  describe "PUT update" do
    before { create_an_annotation! }

    describe "with valid params" do
      it "updates the requested annotation" do
        Annotation.any_instance.should_receive(:update_attributes).with({'note' => 'foo'})
        put :update, {:id => annotation.to_param, book_id: book.to_param, annotation: {'note' => 'foo'}, format: :json}
      end

      it "assigns the requested annotation as @annotation" do
        put :update, {:id => annotation.to_param, book_id: book.to_param, annotation: valid_attributes, format: :json}
        assigns(:annotation).should eq(annotation)
      end

      it "returns a 204 OK HTTP code" do
        put :update, {:id => annotation.to_param, book_id: book.to_param, annotation: valid_attributes, format: :json}

        response.status.should == 204
      end

    end

    describe "with invalid params" do
      it "assigns the annotation as @annotation" do
        put :update, {:id => annotation.to_param, book_id: book.to_param, annotation: {}, format: :json}
        assigns(:annotation).should eq(annotation)
      end

      it "returns a 422 HTTP error" do
        post :create, {book_id: book.to_param, annotation: {"note" => ""}, format: :json}
        response.status.should == 422
      end
    end
  end

  describe "DELETE destroy" do
    before { create_an_annotation! }

    it "destroys the requested annotation" do
      expect {
        delete :destroy, {:id => annotation.to_param, book_id: book.to_param, format: :json}
      }.to change(Annotation, :count).by(-1)
    end

  end

end
