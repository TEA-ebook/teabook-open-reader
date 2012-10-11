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



module TeaApi
  class Request

    # Build a Typhoeus request that can be used on TEA api
    # Credential is automatically added from Gaston config
    # see config/gaston/api.yml
    def self.build(params)
      url = params.delete :url
      cookie = params.delete :cookie
      if Gaston.api['auth'].present?
        params.merge!(username: Gaston.api.auth.username, password: Gaston.api.auth.password)
      end
      params[:headers] = {:Cookie => "PHPSESSID=#{cookie}"} if cookie
      params[:verbose] = Rails.env.development? || Rails.env.dev?
      Rails.logger.info "Request Tea Api on url: #{Gaston.api.host}#{url}"
      Rails.logger.info params.inspect
      Typhoeus::Request.new("#{Gaston.api.host}#{url}", params)
    end

  end
end
