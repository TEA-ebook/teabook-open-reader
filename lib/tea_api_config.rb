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
require 'yaml'


class TeaApiConfig
  
  @path = "config/mock_api/"

  def self.getConf
    return YAML.load_file("#{@path}config.yml")
  end
  
  def self.authentication(id)
    file_path = "#{@path}#{id}/authentication.json"
    File.read file_path if File.exists?(file_path)
  end

  def self.publications(id)
    file_path = "#{@path}#{id}/publications.json"
    File.read file_path if File.exists?(file_path)
  end

  def self.download(id)
    file_path = "#{@path}epubs/#{id}.epub"
    File.read file_path if File.exists?(file_path)
  end

end
