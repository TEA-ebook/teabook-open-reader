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



class App.Models.Component extends Backbone.RelationalModel
  url: ->
    "/ebook/epubs/#{@get('ebook').id}/components/#{@id}.json"

  offlineKey: ->
    "#{App.current_user.id}:ebooks:#{@get('ebook').id}:components:#{@id}"

  storeOffline: ->
    return unless App.Store
    App.Store.set @offlineKey(), @toJSON(), (result)=>
      if result
        @set 'offline', true
        # Use component in event name because listenning for an event on a collection
        # with models that trigger event with the same name will trigger for collection
        # but also for each models
        @trigger 'storeOffline:component:success'
      else
        @trigger 'storeOffline:component:error'

  loadFromStore: ->
    App.Store.get @offlineKey(), (result)=>
      if result
        @set result
        @trigger 'loadFromStore:component:success'
      else
        @trigger 'loadFromStore:component:error'

  removeFromStore: ->
    @set 'removed', false
    App.Store.remove @offlineKey(), (result)=>
      if result
        @set
          offline: false
          removed: true
          content: null
        @trigger 'removeFromStore:component:success'
      else
        @trigger 'removeFromStore:component:error'

  layout: ->
    prop = @get "properties"
    prop["rendition:layout"] if prop

  dimensions: ->
    prop = @get "properties"
    prop["dimensions"].split('x') if prop && prop["dimensions"]

  orientation: ->
    prop = @get "properties"
    prop["rendition:orientation"] if prop

  spread: ->
    prop = @get "properties"
    prop["rendition:spread"] if prop

  pageSpread: ->
    prop = @get "properties"
    return unless prop
    if prop["page-spread-left"]
      "left"
    else if prop["page-spread-right"]
      "right"
    else if prop["rendition:page-spread-center"]
      "center"

  content: ->
    return @get 'content' unless TeaEncryption?
    e = new TeaEncryption(App.current_user.id)
    e.decode(@get 'content')

class App.Collections.Components extends Backbone.Collection
  model: App.Models.Component

  chunkFetch: (options)->
    q = queue(2)
    _.each @models, (model)=>
      q.defer (next)=>
        model.fetch().done =>
          @fetchSuccess(options)
          next()

  fetchSuccess: (options)=>
    completed = _.filter(@models, (model)->
      model.get('content')
    ).length
    @trigger 'download:progress', completed, @size()
    return if completed < @size()
    @trigger 'chunkFetch:success'
    return unless options.store
    q = queue(1)
    _.each @models, (model)=>
      q.defer (next)=>
        model.on 'storeOffline:component:success', =>
          @storeOfflineSuccess()
          next()
        model.on 'storeOffline:component:error', =>
          @trigger 'storeOffline:components:error'
        model.storeOffline()

  storeOfflineSuccess: =>
    completed = _.filter(@models, (model)->
      model.get('offline')
    ).length
    @trigger 'storeOffline:progress', completed, @size()
    return if completed < @size()
    # See Component#storeOffline for explanation of this ugly event name
    @trigger 'storeOffline:components:success'
    _.each @models, (model)=>
      model.unbind 'storeOffline:component:success'
      model.unbind 'storeOffline:component:error'

  loadFromStore: ->
    _.each @models, (model)=>
      model.on 'loadFromStore:component:success', @loadFromStoreSuccess
      model.loadFromStore()

  loadFromStoreSuccess: =>
    return if _.any(@models, (c)->
      _.isEmpty(c.get 'content')
    )
    unless @loadFromStoreSuccessTriggered
      @trigger 'loadFromStore:components:success'
      @loadFromStoreSuccessTriggered = true
    _.each @models, (model)=>
      model.unbind 'loadFromStore:components:success'

  removeFromStore: =>
    _.each @models, (model)=>
      model.on 'removeFromStore:component:success', @removeFromStoreSuccess
      model.removeFromStore()

  removeFromStoreSuccess: =>
    return if _.any(@models, (c)->
      !c.get('removed')
    )
    @trigger 'removeFromStore:components:success'
    _.each @models, (model)=>
      model.unbind 'removeFromStore:components:success'
