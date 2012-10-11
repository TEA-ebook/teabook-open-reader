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



class App.Models.OfflineStore
  constructor: (options = {})->
    @adapter =  new StickyStore
      name: options.name || 'tea-offline-store'
      adapters: ['webSQL', 'indexedDB']
      size: options.initSize || 50
      ready: (store)=>
        store.on 'error', @onStorageError
        options.success() if options.success
        @refreshQuotaStatus()
        @adapter.on('get', @refreshQuotaStatus)
        @adapter.on('set', @refreshQuotaStatus)
        @adapter.on('remove', @refreshQuotaStatus)
        # FIXME no clear event on Sticky (adapter)
        @adapter.on('clear', @refreshQuotaStatus)

    _.extend(@, Backbone.Events)
    @

  onStorageError: (error, item)->
    console.error('Storage error', error)
    @trigger('storeOffline:storage:error', error, item)

  get: (key, callback)=>
    @adapter.get(key, callback)

  set: (key, item, callback)=>
    @adapter.set(key, item, callback)

  remove: (key, callback)=>
    @adapter.remove(key, callback)

  clear: =>
    @adapter.removeAll()

  maxAvailableSpace: ->
    @quotaForPlatform() - @used

  hasAvailableSpaceFor: (byteSize)->
    byteSize <= @remaining

  onMobilePlatform: ->
    !! ((/mobile/i).exec(window.navigator.userAgent))

  hasStorageInfo: ->
    typeof webkitStorageInfo != 'undefined'

  quotaForPlatform: ->
    # TODO: Get smarter than this!
    if @onMobilePlatform()
      50000000
    else
      100000000

  setBookCollection: (collection)->
    @collection = collection
    unless @hasStorageInfo()
      @collection.on 'change:bytesize', (e)=>
        @collection.calculateByteSize()
        @setQuota(@collection.bytesize)

  quotaStatus: =>
    @used ||= 0
    @remaining ||= @quotaForPlatform()
    {used: @used, remaining: @remaining}

  setQuota: (byteSize)=>
    @used = byteSize
    @remaining = (@quotaForPlatform() - @used) / 2 # Damn you, UTF-16!

  refreshQuotaStatus: ()=>
    if @hasStorageInfo()
      # XXX: This info is really not that reliable. Not only can there be a lag
      # in refreshing it, but the underlying SQLite db may be abnormally large 
      # because of a much needed vacuum - Chromium/Linux, I'm looking at you!
      webkitStorageInfo.queryUsageAndQuota webkitStorageInfo.TEMPORARY, (used, remaining) =>
        @used = used
        @remaining = remaining / 2 # Damn you, UTF-16!

    @trigger 'storeOffline:storage:quotaChange'
