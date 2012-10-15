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

describe ManifestsController do

  describe 'GET #reader' do

    before :each do
      get :reader, format: :text
    end

    it 'should render a ApplicationCache Manifest' do
      response.should render_template(:reader)
      response.headers['Content-Type'].should =~ /text\/cache-manifest/
      lines = response.body.split(/\n/)
      lines[0].should == 'CACHE MANIFEST'
      lines[1].should =~ /# Version [0-9]+/
      lines[-3].should == 'NETWORK:'
      lines[-2].should == '*'
      lines[-1].should == 'http://*'
    end

  end

end
