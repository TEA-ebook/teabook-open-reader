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



require "spec_helper"

describe Admin::BooksellersController do
  describe "routing" do

    it "routes to #index" do
      get("/admin/booksellers").should route_to("admin/booksellers#index")
    end

    it "routes to #new" do
      get("/admin/booksellers/new").should route_to("admin/booksellers#new")
    end

    it "routes to #show" do
      get("/admin/booksellers/1").should route_to("admin/booksellers#show", :id => "1")
    end

    it "routes to #edit" do
      get("/admin/booksellers/1/edit").should route_to("admin/booksellers#edit", :id => "1")
    end

    it "routes to #create" do
      post("/admin/booksellers").should route_to("admin/booksellers#create")
    end

    it "routes to #update" do
      put("/admin/booksellers/1").should route_to("admin/booksellers#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/admin/booksellers/1").should route_to("admin/booksellers#destroy", :id => "1")
    end

  end
end
