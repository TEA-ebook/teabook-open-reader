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



class App.Models.Bookmark extends Backbone.Model

  offlineKey: ->
    if @type == 'reading_position'
      "bookmark:#{@get 'user_id'}:#{@get 'epub_id'}:#{@get 'type'}"
    else
      "bookmark:#{@get 'user_id'}:#{@get 'epub_id'}:#{@get 'type'}:#{@id}"

  url: ->
    "/books/#{@get 'epub_id'}/bookmarks/#{@id}"

  # TODO implement online mode
  sync: (method, model, options = {})->
    switch method
      when 'create'
        if App.Store
          App.Store.set @offlineKey(), @toJSON()
      when 'read'
        if App.Store
          App.Store.get @offlineKey(), (result)=>
            @set result if result
            @trigger 'fetched'
      else
        console.log "Bookmark sync #{method} not implemented yet"
    @
