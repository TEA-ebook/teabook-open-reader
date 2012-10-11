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

require "spec_helper_lite"

require "app/models/synchronizers/base"
require "app/models/synchronizers/reading_position"

require "faraday"
require "faraday_middleware"
require "hashie"

require "active_support"
require "active_support/core_ext"

stub_module "Gaston"
stub_module "Rails"

describe Synchronizers::ReadingPosition do

  before do
    Rails.stub(:logger).and_return(null_object)
  end

  let(:user) { mock('user', id: "foo") }
  let(:book) { mock("book", id: "bar", destroyed?: false) }

  let(:config) do
    {"host"  => "http://foobar.com",
     "paths" => {
       "reading_position" => {
          "post"   => "/users/foo/base",
          "get"    => "/users/foo/base/42",
          "put"    => "/users/foo/base/42",
          "delete" => "/users/foo/base/42"
       }
      }
    }
  end
  let(:fake_adapter) { Faraday::Adapter::Test::Stubs.new  }

  subject { described_class.new(user, config: config, adapter: [:test, fake_adapter]) }

  describe "when updating a local record" do

    before do
      fake_adapter.get('/users/foo/base/42') { [200, {}, {}] }
      subject.should_receive(:stale_remote?).and_return(false)
      subject.should_receive(:stale_local?).and_return(true)
    end

    it "voids #locus" do
      book.should_receive(:update_attributes)

      book.should_receive(:locus=).with(nil)
      subject.synchronize!(book)
    end

  end


end
