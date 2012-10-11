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

describe BookLocation do

  it "has a valid factory" do
    Fabricate.build(:book_location).should be_valid
  end

  describe "relations" do
    it { should be_referenced_in(:user) }
    it { should be_referenced_in(:book) }
  end

  describe "#user_id" do
    it "is mandatory" do
      described_class.new(user_id: nil).error_on(:user_id).should_not be_blank
    end
  end

  describe "#book_id" do
    it "is mandatory" do
      described_class.new(book_id: nil).error_on(:book_id).should_not be_blank
    end
  end

  describe "#component_name" do

    subject do
      loc =  Fabricate.build(:book_location)
      loc.component_name = nil
      loc
    end

    context "if the book is not already converted" do
      it "is optional" do
        subject.book.stub(:converted?).and_return(false)
        subject.valid?
        subject.error_on(:component_name).should be_blank
      end
    end

    context "if the book is converted" do
      it "is mandatory" do
        subject.book.stub(:converted?).and_return(true)
        subject.valid?
        subject.error_on(:component_name).should_not be_blank
      end
    end
  end

  describe "#epub_cfi" do

    context "when there is a component_name" do

      subject { Fabricate.build(:book_location) }

      it "is filled in automatically" do
        subject.should_receive(:build_cfi!)
        subject.save
      end
    end

    context "when there is no component_name" do
      subject do
        loc =  Fabricate.build(:book_location)
        loc.component_name = nil
        loc
      end

      it "is not filled in" do
        subject.should_not_receive(:build_cfi!)
        subject.save
      end
    end

  end


end
