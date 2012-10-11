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



class App.Views.EbookReader extends Backbone.View

  initialize: (options)->
    @params = options.params
    @model.on 'offline:status', @fetchPosition

  listenForSandboxMessages: ->
    App.messages.register @$('iframe').get(0).contentWindow, '*'
    App.messages.on 'receive:sandbox:ready', =>
      @model.fetch success: =>
        @model.checkOffline()

    # Bind some posteMessage messages to methods
    App.messages.on 'receive:component:fetch', @fetchComponent
    App.messages.on 'receive:readingPosition:save', @saveReadingPosition
    App.messages.on 'receive:openExternalLink', @openExternalLink
    App.messages.on 'receive:navigate', @navigate

  fetchPosition: =>
    @model.set 'readingPosition', new App.Models.ReadingPosition
      book_id: @model.id
      user_id: App.current_user.id
    if locus = @locusFromParams()
      @model.get('readingPosition').set 'locus', locus
      @initializeReader()
    else
      @model.get('readingPosition').fetch()
      @model.get('readingPosition').on 'fetched', =>
        @initializeReader()

  locusFromParams: ->
    return if _.isEmpty @params
    locus = {componentId: @params[0]}
    if @params[1]
      locus.anchor = @params[1]
    else
      locus.percent = 0
    locus

  initializeReader: =>
    App.messages.send
      type: 'initialize'
      content: @model.toJSON()

  render: =>
    @$('#reader').html SMT['ebook/reader'] @model.toJSON()
    @listenForSandboxMessages()
    @

  # Proxy methods for sandboxed iframe
  #

  fetchComponent: (cjson)=>
    component = new App.Models.Component cjson
    component.fetch().done =>
      App.messages.send
        type: "component:fetched:#{component.id}"
        content: component.toJSON()

  saveReadingPosition: (rjson)=>
    @model.set 'readingPosition', new App.Models.ReadingPosition(rjson)
    @model.get('readingPosition').save()

  navigate: (href)->
    window.location = href

  openExternalLink: (href)->
    window.open href
