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

describe Admin::BooksellersController do

  let(:admin){ Fabricate(:admin) }

  before :each do
    sign_in admin
  end

  def valid_attributes
    Fabricate.attributes_for(:bookseller)
  end

  describe "GET index" do
    it "assigns all booksellers as @booksellers" do
      bookseller = Bookseller.create! valid_attributes
      get :index, {}
      assigns(:booksellers).should eq([bookseller])
    end
  end

  describe "GET show" do
    it "assigns the requested bookseller as @bookseller" do
      bookseller = Bookseller.create! valid_attributes
      get :show, {:id => bookseller.to_param}
      assigns(:bookseller).should eq(bookseller)
    end
  end

  describe "GET new" do
    it "assigns a new bookseller as @bookseller" do
      get :new, {}
      assigns(:bookseller).should be_a_new(Bookseller)
    end
  end

  describe "GET edit" do
    it "assigns the requested bookseller as @bookseller" do
      bookseller = Bookseller.create! valid_attributes
      get :edit, {:id => bookseller.to_param}
      assigns(:bookseller).should eq(bookseller)
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "creates a new Bookseller" do
        expect {
          post :create, {:bookseller => valid_attributes}
        }.to change(Bookseller, :count).by(1)
      end

      it "assigns a newly created bookseller as @bookseller" do
        post :create, {:bookseller => valid_attributes}
        assigns(:bookseller).should be_a(Bookseller)
        assigns(:bookseller).should be_persisted
      end

      it "redirects to the created bookseller" do
        post :create, {:bookseller => valid_attributes}
        response.should redirect_to([:admin, Bookseller.last])
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved bookseller as @bookseller" do
        # Trigger the behavior that occurs when invalid params are submitted
        Bookseller.any_instance.stub(:save).and_return(false)
        post :create, {:bookseller => {}}
        assigns(:bookseller).should be_a_new(Bookseller)
      end

      it "re-renders the 'new' template" do
        # Trigger the behavior that occurs when invalid params are submitted
        Bookseller.any_instance.stub(:save).and_return(false)
        post :create, {:bookseller => {}}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested bookseller" do
        bookseller = Bookseller.create! valid_attributes
        # Assuming there are no other booksellers in the database, this
        # specifies that the Bookseller created on the previous line
        # receives the :update_attributes message with whatever params are
        # submitted in the request.
        Bookseller.any_instance.should_receive(:update_attributes).with({'these' => 'params'})
        put :update, {:id => bookseller.to_param, :bookseller => {'these' => 'params'}}
      end

      it "assigns the requested bookseller as @bookseller" do
        bookseller = Bookseller.create! valid_attributes
        put :update, {:id => bookseller.to_param, :bookseller => valid_attributes}
        assigns(:bookseller).should eq(bookseller)
      end

      it "redirects to the bookseller" do
        bookseller = Bookseller.create! valid_attributes
        put :update, {:id => bookseller.to_param, :bookseller => valid_attributes}
        response.should redirect_to([:admin, bookseller])
      end
    end

    describe "with invalid params" do
      it "assigns the bookseller as @bookseller" do
        bookseller = Bookseller.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Bookseller.any_instance.stub(:save).and_return(false)
        put :update, {:id => bookseller.to_param, :bookseller => {}}
        assigns(:bookseller).should eq(bookseller)
      end

      it "re-renders the 'edit' template" do
        bookseller = Bookseller.create! valid_attributes
        # Trigger the behavior that occurs when invalid params are submitted
        Bookseller.any_instance.stub(:save).and_return(false)
        put :update, {:id => bookseller.to_param, :bookseller => {}}
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested bookseller" do
      bookseller = Bookseller.create! valid_attributes
      expect {
        delete :destroy, {:id => bookseller.to_param}
      }.to change(Bookseller, :count).by(-1)
    end

    it "redirects to the booksellers list" do
      bookseller = Bookseller.create! valid_attributes
      delete :destroy, {:id => bookseller.to_param}
      response.should redirect_to(admin_booksellers_url)
    end
  end

end
