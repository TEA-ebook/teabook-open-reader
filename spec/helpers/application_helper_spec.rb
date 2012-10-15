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


require 'spec_helper'

describe ApplicationHelper do
  let(:bookseller) { Fabricate(:bookseller, bookstore_id: 'tea') }

  describe 'bookseller_stylesheet' do

    it 'should return the bookseller stylesheet link tag if exists (file also must exists on fs)' do
      helper.stub(:current_bookseller).and_return(bookseller)
      helper.bookseller_stylesheet.should == "<link href=\"/assets/#{bookseller.stylesheet}.css\" media=\"all\" rel=\"stylesheet\" type=\"text/css\" />"
    end

    it 'should return the default stylesheet if we are on the generic website' do
      helper.stub(:current_bookseller).and_return(nil)
      helper.bookseller_stylesheet.should == "<link href=\"/assets/application.css\" media=\"all\" rel=\"stylesheet\" type=\"text/css\" />"
    end

  end
end
