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

describe TeaApi::Session do

  let (:authentication_json) { File.read('spec/fixtures/api/authentication.json') }
  let (:authentication_error_json) { File.read('spec/fixtures/api/authentication_error.json') }

  describe 'attributes' do

    it 'should defined accessors' do
      s = TeaApi::Session.new email: 'email@example.com', password: 'password', bookstore: 'bookstore'
      s.email.should == 'email@example.com'
      s.password.should == 'password'
      s.bookstore.should == 'bookstore'
      s.session.should be_nil
    end

  end

  describe 'save' do

    it 'should return true on success api response and set attributes' do
      response = Typhoeus::Response.new(:code => 200, :body => authentication_json)
      Typhoeus::Hydra.hydra.stub(:post, "#{Gaston.api.host}/app/authentication").and_return(response)
      s = TeaApi::Session.new email: 'email@example.com', password: 'password', bookstore: 'bookstore'
      s.save.should be_true
      s.session.should == {"id" => "ec115cd99c07e710413b01bc2799e026", "expire" => 1374329344}
      s.firstname.should == "John"
      s.lastname.should == "Doe"
      s.birthdate.should == "1980-07-30T01:00:00+01:00"
      s.country.should == "FR"
    end

    it 'should return false on api error and set errors' do
      response = Typhoeus::Response.new(:code => 403, :body => authentication_error_json)
      Typhoeus::Hydra.hydra.stub(:post, "#{Gaston.api.host}/app/authentication").and_return(response)
      s = TeaApi::Session.new email: 'email@example.com', password: 'password', bookstore: 'bookstore'
      s.save.should be_false
      s.errors[:base].should == ["AUTH_ERROR : Utilisateur non valide."]
    end

  end
end
