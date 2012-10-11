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
require "spec_helper"

describe Ebook::EpubsController do
  describe "routing" do

    it "routes to #index" do
      get("/ebook/epubs").should route_to("ebook/epubs#index")
    end

    it "routes to #new" do
      get("/ebook/epubs/new").should route_to("ebook/epubs#new")
    end

    it "routes to #show" do
      get("/ebook/epubs/1").should route_to("ebook/epubs#show", id: "1")
    end

    it "routes to #edit" do
      get("/ebook/epubs/1/edit").should route_to("ebook/epubs#edit", id: "1")
    end

    it "routes to #create" do
      post("/ebook/epubs").should route_to("ebook/epubs#create")
    end

    it "routes to #update" do
      put("/ebook/epubs/1").should route_to("ebook/epubs#update", id: "1")
    end

    it "routes to #destroy" do
      delete("/ebook/epubs/1").should route_to("ebook/epubs#destroy", id: "1")
    end

    it "routes to #reader" do
      get("/ebook/epub").should route_to("ebook/epubs#reader", format: :html)
      get("/ebook/epub.html").should route_to("ebook/epubs#reader", format: 'html')
    end

    it "routes to #reader_sandbox" do
      get("/ebook/epub_sandbox").should route_to("ebook/epubs#reader_sandbox", format: :html)
      get("/ebook/epub_sandbox.html").should route_to("ebook/epubs#reader_sandbox", format: 'html')
    end

    describe 'offline' do

      it "routes to #index" do
        get("/offline/ebook/epubs").should route_to("ebook/epubs#index", offline: true, format: :html)
      end

      it "routes to #reader" do
        get("/offline/ebook/epub").should route_to("ebook/epubs#reader", format: :html, offline: true)
        get("/offline/ebook/epub.html").should route_to("ebook/epubs#reader", format: 'html', offline: true)
      end

      it "routes to #reader_sandbox" do
        get("/offline/ebook/epub_sandbox").should route_to("ebook/epubs#reader_sandbox", format: :html, offline: true)
        get("/offline/ebook/epub_sandbox.html").should route_to("ebook/epubs#reader_sandbox", format: 'html', offline: true)
      end

    end
  end
end
