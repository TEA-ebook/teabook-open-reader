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



class App.Models.Ebook extends Backbone.RelationalModel

  relations: [
    {
      type: Backbone.HasMany
      key: 'components'
      relatedModel: 'App.Models.Component'
      collectionType: 'App.Collections.Components'
      reverseRelation:
        key: 'ebook'
        includeInJSON: '_id'
    },
    {
      type: Backbone.HasMany
      key: 'chapters'
      relatedModel: 'App.Models.Chapter'
      collectionType: 'App.Collections.Chapters'
    },
    {
      type: Backbone.HasOne
      key: 'readingPosition'
      relatedModel: 'App.Models.ReadingPosition'
    }
  ]

  preload:
    forward: 2
    backward: 1

  defaults:
    offline: false

  url: ->
    "/ebook/epubs/#{@id}.json"

  offlineKey: ->
    "#{App.current_user.id}:ebooks:#{@id}"

  initialize: (attrs)->
    @listenComponents()
    super attrs

  listenComponents: ->
    @get('components').on 'loadFromStore:components:success', =>
      @trigger 'loadFromStore:success'
    @get('components').on 'download:progress', (done, total)=>
      @trigger 'download:progress', done, total
    @get('components').on 'storeOffline:progress', (done, total)=>
      @trigger 'storeOffline:progress', done, total
    @get('components').on 'storeOffline:components:error', =>
      @trigger 'download:failed'
    @get('components').on 'storeOffline:components:success', =>
      # We don't want to store content in the global Ebook object
      json = @toJSON()
      json['components'] = _.map(@get('components').models, (model)->
        _.pick(model.attributes, '_id', 'src')
      )
      App.Store.set @offlineKey(), json, (result)=>
        if result
          @set 'offline', true
          @trigger 'download:complete'
        else
          @trigger 'download:failed'
    @get('components').on 'removeFromStore:components:success', =>
      App.Store.remove @offlineKey(), (result)=>
        if result
          @set 'offline', false
          @trigger 'remove:success'
        else
          @trigger 'remove:failed'

  sync: (method, model, options = {})->
    if App.Store
      switch method
        when 'read'
          App.Store.get model.offlineKey(), (result)=>
            if result
              model.set result
              model.on 'loadFromStore:success', ->
                options.success() if options.success
              model.loadComponentsFromStore()
            else
              Backbone.sync(method, model, options)
    else
      Backbone.sync(method, model, options)

  loadComponentsFromStore: ->
    @get('components').loadFromStore()

  checkOffline: =>
    # If Sticky is not connected to an adapter
    # Force offline attribute and trigger offline:status event
    unless App.Store
      @set 'offline', false
      @trigger 'offline:status'
    else
      App.Store.get @offlineKey(), (result)=>
        if result
          @set result
          if @get('chapters') && @get('components')
            @set 'offline', true
          else
            @set 'offline', false
        else
          @set 'offline', false
        @trigger 'offline:status'

  download: ->
    if App.Store
      @trigger 'download:started'
      @fetch
        success: =>
          @get('components').chunkFetch(store: true)
        error: =>
          @trigger 'download:failed'
    else
      @trigger 'download:failed'

  remove: ->
    @trigger 'remove:started'
    if App.Store
      @get('components').removeFromStore()
    else
      @trigger 'remove:failed'

  layout: ->
    prop = @get "properties"
    prop["rendition:layout"] if prop

  orientation: ->
    prop = @get "properties"
    prop["rendition:orientation"] if prop

  spread: ->
    prop = @get "properties"
    prop["rendition:spread"] if prop

  printable: ->
    @get('license') != 'drm'

  # Monocle interface
  #

  getComponents: ->
    @get('components').pluck 'src'

  getContents: ->
    @get('chapters').toJSON()

  getComponent: (componentSrc, callback)->
    component = _.first(@get('components').where(src: componentSrc))
    fn = =>
      # If we have a callback, this is a Monocle call
      # and we want to preload next/prev components
      if callback
        options =
          layout: component.layout() || @layout()
          orientation: component.orientation() || @orientation()
          spread: component.spread() || @spread()
          pageSpread: component.pageSpread()
          dimensions: component.dimensions()
        @preloadComponents(component)
        callback @sanitizeText(component.content()), options

    if component.get 'content'
      fn()
    else
      if @.get 'sandbox'
        App.messages.on "receive:component:fetched:#{component.id}", (c)=>
          component.set 'content', c.content
          fn()
        App.messages.send
          type: 'component:fetch'
          content: component.toJSON()
      else
        component.fetch().done fn
    null

  # Preload next/previous components for better performance
  # while turning pages
  #
  preloadComponents: (component)=>
    coll = @get 'components'
    currentIndex = coll.indexOf(component)
    components = []
    for i in [1..@preload.forward]
      components.push coll.at(currentIndex + i)
    for i in [1..@preload.backward]
      components.push coll.at(currentIndex - i)
    for c in components
      if c && !c.get 'content'
        @getComponent(c.get 'src', false)

  getMetaData: (key)=>
    if key
      @get(key) || @get('properties')[key]
    else
      @get 'properties'

  chaptersWithLinksJSON: =>
    _.map(@get('chapters').models, (c)=>
      c.set 'link', "/ebook/epub##{@id}|#{c.get('src').replace('#', "|")}"
      c.toJSON()
    )

  sanitizeText: (content)->
    # FIXME quick fix for Firefox and iPad
    # Need to escape \ on these browsers
    if /firefox|ipad/i.test(window.navigator.userAgent)
      content.replace(/\\/g, '\\\\')
    else
      content

class App.Collections.Ebooks extends Backbone.Collection
  model: App.Models.Ebook

  bytesize: 0

  offlineKey: ->
    if App.bookstore
      "#{App.current_user.id}:ebooks:#{App.bookstore}"
    else
      "#{App.current_user.id}:ebooks:all"

  url: ->
    '/ebook/epubs.json'

  sync: (method, model, options = {})->
    if App.onLine
      if method == 'read' && App.Store
        success = options.success||->
        options.success = (collection, resp)->
          success(collection, resp)
          App.Store.set model.offlineKey(), collection
      Backbone.sync(method, model, options)
    else
      switch method
        when 'read'
          App.Store.get model.offlineKey(), (result)=>
            model.reset result if result
        else
          console.log "offlineSync don't implement #{method} for now"

  comparator: (item)->
    switch item.collection.order
      when 'publisher'
        if item.get('publisher')?['publisher_name']
          @sanitizeSortString item.get('publisher')?['publisher_name']
      when 'author'
        if item.get('authors')
          author = _.find(item.get('authors'), (author)->
            author?['main'] == true
          )
          @sanitizeSortString author?.author_name
      when 'read'
        if item.get('reading_position')?['updated_at']
          - new Date(item.get('reading_position')?['updated_at']).getTime()
      when 'purchase'
        if item.get('purchase')?['date']
          - new Date(item.get('purchase')?['date']).getTime()
      when 'offline'
        title = @sanitizeSortString item.get('title')
        if item.get 'offline'
          "0-#{title}"
        else
          "1-#{title}"
      else
        @sanitizeSortString item.get('title')

  sanitizeSortString: (string)->
    return undefined unless string
    s = string.toLowerCase()
    s = s.replace(new RegExp(/[àáâãäå]/g),"a")
    s = s.replace(new RegExp(/æ/g),"ae")
    s = s.replace(new RegExp(/ç/g),"c")
    s = s.replace(new RegExp(/[èéêë]/g),"e")
    s = s.replace(new RegExp(/[ìíîï]/g),"i")
    s = s.replace(new RegExp(/ñ/g),"n")
    s = s.replace(new RegExp(/[òóôõö]/g),"o")
    s = s.replace(new RegExp(/œ/g),"oe")
    s = s.replace(new RegExp(/[ùúûü]/g),"u")
    s = s.replace(new RegExp(/[ýÿ]/g),"y")
    s


  calculateByteSize: ->
    @bytesize = 0
    for model in @models
      @bytesize += model.get 'bytesize' if model.get 'offline'
