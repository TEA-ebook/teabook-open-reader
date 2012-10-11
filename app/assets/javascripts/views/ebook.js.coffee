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



class App.Views.Ebook extends Backbone.View
  tagName: 'article'

  events:
    'click .download':  'download'
    'click .remove':    'remove'

  initialize: (options)->
    $('.loader').hide()

    # TODO keep it simple !
    @model.on 'download:started', =>
      @$('.download').attr('disabled', 'disabled')
    @model.on 'download:complete download:failed', =>
      @$('.downloadProgress').hide()
    @model.on 'download:progress', (done, total)=>
      @downloadLoader 'download', done, total

    @model.on 'remove:success remove:failed', =>
      @$('.loader').hide()
    @model.on 'remove:started', =>
      @$('.loader').show()

    @model.on 'storeOffline:progress', (done, total)=>
      @downloadLoader 'storeOffline', done, total
    @model.on 'change:offline offline:status remove:success', =>
      @model.collection.trigger 'change:bytesize'
      @updateOfflineStatus()

    $('body').on 'online offline', =>
      @updateAvailableActions()
    @model.checkOffline()

  download: (e)->
    e.preventDefault()
    @model.download() if App.onLine && App.Store.hasAvailableSpaceFor(@model.get('bytesize'))

  render: ->
    @$el.html(SMT['ebook/item_list'] @formattedJSON())
      .append(new App.Views.EbookDetail(model: @model).render().el)
      .addClass @model.get 'state'

    @updateAvailableActions()
    @updateOfflineStatus()
    @

  formattedJSON: =>
    _.extend @model.toJSON(), reading_position: @formattedReadingPosition(@model.get('reading_position'))

  formattedReadingPosition: (rp)->
    percentage = (rp.percentage*100).toFixed() if rp.percentage
    date = moment(rp.updated_at).fromNow() if rp.updated_at

    {percentage: percentage, updated_at: date}

  # TODO keep it simple !
  updateOfflineStatus: ->
    if @model.get 'offline'
      @$el.addClass 'availableOffline'
    else
      @$el.removeClass 'availableOffline'
    unless App.Store.hasAvailableSpaceFor(@model.get('bytesize'))
      @$el.removeClass 'downloadable'
      @$('.download').addClass('hide')
    else
      @$el.addClass 'downloadable'

    if @model.get 'offline'
      @$('.download').addClass 'hide'
      @$('.read').removeClass('only-online')
        .removeAttr('disabled')
      @$('.remove').removeClass 'hide'
    else
      @$('.remove').addClass 'hide'
      @$('.read').addClass('only-online')
      if App.onLine && App.Store.hasAvailableSpaceFor(@model.get('bytesize'))
        @$('.download').removeClass('hide')
          .removeAttr('disabled')
      else
        @$('.read').attr('disabled', 'disabled')

  updateAvailableActions: ->
    unless App.onLine
      @$('.only-online').attr('disabled', 'disabled')
    else
      @$('.only-online').removeAttr('disabled')

  remove: (e)->
    e.preventDefault()
    @progress = null
    @model.remove()

  downloadLoader: (type, done, total)=>
    unless @progress
      @progress =
        download:
          done: 0
          total: 0
        checkOffline:
          done: 0
          total: 0
    @progress[type] =
      done: done
      total: total
    done = (@progress.download?.done || 0) + (@progress.storeOffline?.done || 0)
    total = @progress.download?.total * 2
    percent = (done/total*100).toFixed()
    @$('.downloadProgress .bar').css
      width: "#{percent}%"
    @$('.downloadProgress').show()
