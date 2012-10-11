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



class App.Models.Annotation extends Backbone.Model
  initialize: (book_id, componentName, range, note)->
    @textLocator = new App.Misc.TextLocator
    @set 'book_id', book_id
    @set 'component_name', componentName
    @set 'note', note
    @set 'start_xpath', @textLocator.nodeToXpath(range.startContainer)
    @set 'end_xpath', @textLocator.nodeToXpath(range.endContainer)
    @set 'start_offset', range.startOffset
    @set 'end_offset', range.endOffset

  offlineKey: ->
    "#{App.current_user.id}:ebooks:#{@get 'book_id'}:annotations:#{@id}"

  urlRoot: ->
    "/books/#{@get 'book_id'}/annotations"

  sync: (method, model, options = {})->
    switch method
      when 'create', 'update'
        if App.Store
          App.Store.set @offlineKey(), @toJSON()
        Backbone.sync(method, model, options)
      when 'read'
        if App.Store
          App.Store.get @offlineKey(), (result)=>
            @set result if result
            Backbone.sync(method, model, options)
            @trigger 'fetched'
        else
          Backbone.sync(method, model, options)
    @

  schema:
    note: 'TextArea'
