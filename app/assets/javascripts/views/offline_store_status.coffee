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



class App.Views.OfflineStoreStatus extends Backbone.View
  tagName: 'section'
  className: 'modal'
  id: 'offlineStorage'

  events:
    'click a.remove':     'remove'
    'click a.removeAll':  'removeAll'

  initialize: ->
    @lockRender = false
    @model.on 'storeOffline:storage:quotaChange', @updateInfos
    @model.collection.on 'remove:success remove:failed', =>
      @lockRender = false
      @$('.loader').hide()
      @updateInfos()
    @model.collection.on 'remove:started', =>
      @lockRender = true
      @$('.loader').show()

  render: =>
    @updateInfos()
    @$el.hide()
    @

  updateInfos: =>
    unless @lockRender
      offlineModels = new App.Collections.Ebooks(@model.collection.where(offline: true))
      if offlineModels.length
        @$el.html SMT['offline_store_status']
          percentage: @percentage()
          ebooks: offlineModels.toJSON()
      else
        @$el.html SMT['offline_store_status_empty']

  percentage: ->
    percent = (100 * @model.quotaStatus().used / @model.quotaStatus().remaining).toFixed()
    return 100 if percent > 100
    percent

  remove: (e)->
    e.preventDefault()
    elem = $(e.currentTarget)
    @model.collection.get(elem.data('ebook_id')).remove()

  removeAll: (e)->
    e.preventDefault()
    # Don't use App.Store.clear because don't trigger quotaChange event
    for model in @model.collection.models
      model.remove()
