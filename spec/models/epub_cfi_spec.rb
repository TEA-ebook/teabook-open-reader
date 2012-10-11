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
require "app/models/epub_cfi"
require "nokogiri"
require "active_support"
require "active_support/core_ext"

describe EpubCfi do

  let(:opf) { File.read("#{RAILS_ROOT}/spec/fixtures/cfi/itemrefs_with_ids/package_document.opf") }

  let(:book) do
    book = mock("book")
    book.stub(:package_document).and_return(opf)
    book
  end

  subject { described_class.new(book) }

  let(:component) do
    component = mock("component")
    component.stub(:content).and_return File.read("#{RAILS_ROOT}/spec/fixtures/cfi/itemrefs_with_ids/epub30-titlepage.xhtml")

    component
  end

  before do
    book.stub(:component_with_src).and_return(component)
  end

  describe "#path" do

    context "with no text offset" do
      it "returns the right result" do
        subject.path("//body/div/p[1]/a[1]", "xhtml/epub30-titlepage.xhtml").should == "/6/2[ttlref]!/4/6/2[paragraph_id]/2"
      end
    end

  end

  describe "#range" do

    it "returns the right result" do
      # The range starts from the before word "documents" in "The |documents canonically" ('body > p > em')
      # and ends right after the last dot in p#paragraph_id.
      subject.range("xhtml/epub30-titlepage.xhtml", "//body/p[1]/em[1]/text()[1]", 4, "//body/div/p[1]/text()[2]", 1).
        should == "/6/2[ttlref]!/4,/4/2/1:4,/6/2[paragraph_id]/3:1"
    end

  end

end
