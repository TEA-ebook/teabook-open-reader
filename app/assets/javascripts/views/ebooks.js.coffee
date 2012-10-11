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



class App.Views.Ebooks extends Backbone.View
  tagName: 'section'
  className: 'ebooks'

  events:
    'change select[name=sort]':   'sort'
    'click .listMode':            'switchDisplayMode'

  initialize: ->
    App.Store.setBookCollection @collection
    @offlineStoreStatus = new App.Views.OfflineStoreStatus(model: App.Store)
    @collection.on 'reset', @render
    @collection.on 'add', @addEbook
    @collection.order = 'offline' unless App.onLine
    # Usefull to count how many ebook know its offline status
    @cpt = 0
    @collection.on 'offline:status', =>
      @cpt++
      # When all ebook know offline status, sort collection of order is offline
      if @cpt == @collection.length && @collection.order == 'offline'
        @collection.sort()
    @collection.fetch()
    $('body').on 'online', =>
      @collection.fetch()

  render: =>
    @$el.html SMT['ebook/index']
    @$('.offlineStoreStatus').html @offlineStoreStatus.render().el
    @$('select[name=sort]').val @collection.order
    for ebook in @collection.models
      @addEbook ebook
    @applyDisplayMode()
    @el

  addEbook: (ebook)=>
    @$el.append new App.Views.Ebook(model: ebook).render().el

  sort: ->
    @collection.order = @$('select[name=sort]').val()
    @collection.sort()

  switchDisplayMode: (e)->
    e.preventDefault()
    if @displayMode() == 'detailled'
      $.cookie('displayMode', 'compact')
    else
      $.cookie('displayMode', 'detailled')
    @applyDisplayMode()

  applyDisplayMode: ->
    if @displayMode() == 'detailled'
      @$el.addClass 'detailled'
    else
      @$el.removeClass 'detailled'

  displayMode: ->
    $.cookie('displayMode')
