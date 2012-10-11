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

describe Bookseller do

  let(:bookseller) { Fabricate(:bookseller, bookstore_id: "tea") }

  describe 'fields' do
    it { should have_field(:name) }
    it { should have_field(:bookstore_id) }
    it { should have_field(:domain) }
    it { should have_field(:catalog_url) }
  end

  describe 'validations' do
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:bookstore_id) }
    it { should validate_presence_of(:domain) }
    it { should validate_presence_of(:catalog_url) }

    it { should validate_uniqueness_of(:name) }
    it { should validate_uniqueness_of(:bookstore_id) }
    it { should validate_uniqueness_of(:domain) }
  end

  describe 'stylesheet' do
    it 'should return its customized stylesheet name' do
      bookseller.stylesheet.should == "customization_#{bookseller.bookstore_id}"
    end
  end

end
