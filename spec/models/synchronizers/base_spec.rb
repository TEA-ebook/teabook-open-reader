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



require "spec_helper_lite"

require "app/models/synchronizers/base"

require "faraday"
require "faraday_middleware"
require "hashie"

require "active_support"
require "active_support/core_ext"

stub_module "Gaston"
stub_module "Rails"


describe Synchronizers::Base do

  before do
    Rails.stub(:logger).and_return(null_object)
  end

  let(:user) { mock('user', id: "foo") }
  let(:fake_adapter) { Faraday::Adapter::Test::Stubs.new  }
  let(:book) { mock('book', id: "42", destroyed?: false, updated_at: 2.hours.ago, empty?: false) }

  subject { described_class.new(user, config: config, adapter: [:test, fake_adapter]) }

  let(:config) do
    {"host"  => "http://foobar.com",
     # "auth"  => {"username" => "godalmighty", "password" => "chucknorris"},
     "paths" => {
       "base" => {
          "post"   => "/users/foo/base",
          "get"    => "/users/foo/base/42",
          "put"    => "/users/foo/base/42",
          "delete" => "/users/foo/base/42"
       }
      }
    }
  end

  describe "#synchronize!" do

    context "if there is no remote record" do

      before do
        fake_adapter.get('/users/foo/base/42') { [404, {}, {}] }
      end

      it "creates the remote record" do
        fake_adapter.put("/users/foo/base/42", book) { [201, {}, {} ] }
        subject.synchronize!(book)
        fake_adapter.verify_stubbed_calls
      end

    end

    context "if there is a remote record" do

      let(:remote) { mock("remote", id: "42") }

      before do
        fake_adapter.get('/users/foo/base/42') { [200, {}, remote] }
      end

      context "that should be refreshed by the local record" do

        before do
          subject.should_receive(:stale_remote?).and_return(true)
        end

        it "updates the remote record" do
          fake_adapter.put("/users/foo/base/42", book) { [204, {}, book ] }
          subject.synchronize!(book)
          fake_adapter.verify_stubbed_calls
        end

      end

      context "that should refresh the local record" do

        before do
          subject.should_receive(:stale_remote?).and_return(false)
          subject.should_receive(:stale_local?).and_return(true)
        end

        it "updates the local record" do
          book.should_receive(:update_attributes).with(remote)
          subject.synchronize!(book)
          fake_adapter.verify_stubbed_calls
        end

      end

      context "but the local record was destroyed" do

        before do
          subject.should_receive(:destroyed_local?).and_return(true)
        end

        it "destroys the remote record" do
          fake_adapter.delete("/users/foo/base/42") { [200, {}, {} ] }
          subject.synchronize!(book)
          fake_adapter.verify_stubbed_calls
        end
      end

    end

  end

end
