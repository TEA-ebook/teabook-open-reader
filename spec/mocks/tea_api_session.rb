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



def mock_tea_api_session(stubs={})
  mock = mock_model(TeaApi::Session, stubs)
  mock.stub!(:id).and_return('identifier')
  mock.stub!(:email).and_return('mail@example.com')
  mock.stub!(:password).and_return('password')
  mock.stub!(:bookstore).and_return('bookstore')
  mock.stub!(:session).and_return({'id' => '42', 'expire' => (Time.now + 1.day).to_i})

  mock
end

