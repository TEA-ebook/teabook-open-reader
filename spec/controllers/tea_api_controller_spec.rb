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
require 'sinatra'
path = File.dirname(__FILE__)
require File.join(path, '../../lib/tea_api')
require File.join(path, '../../lib/tea_api_config')
require 'rspec'
require 'rack/test'
require 'pp'

set :environment, :test


RSpec.configure do |conf|
  conf.include Rack::Test::Methods
end

describe TeaApi do

  def app
    TeaApi
  end

  def yes_api_config
    {
      :yesapi=>true, 
      :default=>{
        :authentication=>"config/mock_api/authentication.json", 
        :forbidden=>"spec/fixtures/api/forbidden.json", 
        :publications=>"spec/fixtures/api/publications.json", 
        :download=>"spec/fixtures/api/example.epub"
      }, 
      :users=>[]
    }
  end

  def fake_api_config
    {
      :yesapi=>false, 
      :default=>{
        :authentication=>"config/mock_api/authentication.json", 
        :forbidden=>"config/mock_api/forbidden.json", 
        :publications=>"config/mock_api/publications.json", 
        :download=>"config/mock_api/epubs/example.epub"
      }, 
      :users=>[
        {:id=>1, :email=>"johndoe@user.com", :password=>"ilovejane"},
        {:id=>2, :email=>"janedoe@user.com"}
      ]
    }
  end

  describe 'authentication' do

    describe 'with yesmode' do
      it 'should always return yes' do
        TeaApiConfig.should_receive(:getConf).and_return(yes_api_config)

        post '/app/authentication', params={}
        last_response.status.should == 200
      end
    end

    describe 'without yesmode' do

      describe 'with an invalid user' do        
        it 'should return 403' do
          TeaApiConfig.should_receive(:getConf).twice.and_return(fake_api_config)

          post '/app/authentication', params='{"user": { "email": "invalid@user.com", "password": "hello", "bookstore": "tea"}}'
          last_response.status.should == 403
          last_response.body.include?("forbidden")
        end
      end

      describe 'with a valid user with invalid password' do
        it 'should return 403' do
          TeaApiConfig.should_receive(:getConf).twice.and_return(fake_api_config)

          post '/app/authentication', params='{"user": { "email": "johndoe@user.com", "password": "invalidpassword", "bookstore": "tea"}}'
          last_response.status.should == 403
        end
      end

      describe 'with a valid user with a valid password' do
        it 'should return 200' do
          TeaApiConfig.should_receive(:getConf).and_return(fake_api_config)
          TeaApiConfig.should_receive(:authentication).and_return(File.read "spec/fixtures/api/authentication.json")

          post '/app/authentication', params='{"user": { "email": "johndoe@user.com", "password": "ilovejane", "bookstore": "tea"}}'
          last_response.status.should == 200
        end
      end

    end

  end

  describe 'publications' do
    describe 'with yesmode' do   
      it 'should always return publications' do
        TeaApiConfig.should_receive(:getConf).and_return(yes_api_config)

        get '/users/99/publications'
        last_response.status.should == 200
        last_response.body.include?("Ebook 1")
      end
    end

    describe 'with an invalid user' do   
      it 'should return 403' do
        TeaApiConfig.should_receive(:getConf).twice.and_return(fake_api_config)

        get '/users/99/publications'
        last_response.status.should == 403
      end
    end

    describe 'with a valid user' do   
      it 'should return publications' do
        TeaApiConfig.should_receive(:getConf).and_return(fake_api_config)
        TeaApiConfig.should_receive(:publications).and_return(File.read "spec/fixtures/api/publications.json")

        get '/users/1/publications'
        last_response.status.should == 200
        last_response.body.include?("Ebook 1")
      end
    end
  end

  describe 'download' do
    describe 'with yesmode' do   
      it 'should always return epub' do
        TeaApiConfig.should_receive(:getConf).and_return(yes_api_config)

        get '/publications/99/download'
        last_response.status.should == 200
      end
    end

    describe 'with an invalid user' do   
      it 'should return 403' do
        TeaApiConfig.should_receive(:getConf).twice.and_return(fake_api_config)

        get '/publications/99/download'
        last_response.status.should == 403
      end
    end

    describe 'with a valid user' do   
      it 'should return epub' do
        TeaApiConfig.should_receive(:getConf).and_return(fake_api_config)
        TeaApiConfig.should_receive(:download).and_return(File.read "spec/fixtures/api/example.epub")

        get '/publications/1/download'
        last_response.status.should == 200
      end
    end
  end

end
