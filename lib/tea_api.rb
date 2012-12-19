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

require "json"

class TeaApi < Sinatra::Application

  post '/app/authentication' do
    config = TeaApiConfig.getConf
    if config[:yesapi]
      return File.read config[:default][:authentication]
    elsif !params.keys.first.nil?
      users = config[:users]
      datas = JSON.parse params.keys.first
      email = datas["user"]["email"]
      password = datas["user"]["password"]
      users.each do |u|
        if u[:email] == email
          return TeaApiConfig.authentication(u[:id]) if !u[:password] || u[:password] == password
        end
      end
      403
    end
  end

  error 403 do
    config = TeaApiConfig.getConf
    return File.read config[:default][:forbidden]
  end

  get '/users/:id/publications' do
    config = TeaApiConfig.getConf
    if config[:yesapi]
      return File.read config[:default][:publications]
    else
      publications = TeaApiConfig.publications(params[:id])
      return publications unless publications.nil?
      403
    end
  end

  get '/publications/:id/download' do
    config = TeaApiConfig.getConf
    if config[:yesapi]
      return File.read config[:default][:download]
    else
      epub = TeaApiConfig.download(params[:id])
      return epub unless epub.nil?
      403
    end
  end

end
