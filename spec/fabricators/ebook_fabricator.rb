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



# encoding: utf-8
Fabricator(:ebook, class_name: 'Ebook::Base') do
  file {
    File.open(File.join(Rails.root, 'spec/fixtures/Dictionnaire des idées reçues.epub'))
  }
  title { Faker::Lorem.words }
  source { ['api', 'upload'].sample }
end

Fabricator(:ebook_epub, from: :ebook, class_name: 'Ebook::Epub') do
  components(count: 3) {|parent, i| Fabricate(:ebook_epub_component, ebook: parent )}
  format 'epub'
end

Fabricator(:ebook_epub_api, from: :ebook_epub, class_name: 'Ebook::Epub') do
  source 'api'
  api_id '42'
end

Fabricator(:ebook_epub_upload, from: :ebook_epub, class_name: 'Ebook::Epub') do
  source 'upload'
end
