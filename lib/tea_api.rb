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
    config = getConf
    if config[:yesapi]
      return File.read "config/mock_api/authentication.json"
    else
      users = config[:users]
      datas = JSON.parse params.keys.first
      email = datas["user"]["email"]
      password = datas["user"]["password"]
      users.each do |u|
        if u[:email] == email
          return File.read "config/mock_api/#{u[:id]}/authentication.json" if !u[:password] || u[:password] == password
        end
      end
      403
    end
  end

  error 403 do
    return File.read "config/mock_api/forbidden.json"
  end

  get '/users/:id/publications' do
    config = getConf
    if config[:yesapi]
      File.read "config/mock_api/publications.json"
    else
      File.read "config/mock_api/#{params[:id]}/publications.json"
    end
  end

  get '/publications/:id/download' do
    config = getConf
    if config[:yesapi]
      File.read "config/mock_api/epubs/example.epub"
    else
      File.read "config/mock_api/epubs/#{params[:id]}.epub"
    end
  end

  private
  def getConf
    YAML.load_file("config/mock_api/config.yml")
  end
end
