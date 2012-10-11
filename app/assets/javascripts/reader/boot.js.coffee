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



$(document).ready ->
  #Monocle.DEBUG = true
  App.current_user = new App.Models.User _id: $('body').data('userid')

  new App.Misc.NetworkStatus()

  new App.Misc.AppcacheLoader if $('body').data('userid')

  init = ->
    # Extract params from hash, separator is |.
    # First params is mandatory and represent ebook_id.
    # Second params is optional and represent chapter path
    # Third params is optional and represent chapter hash
    #
    params = window.location.hash.replace('#', '').split('|')
    id = params.shift()

    # After extracting params, we reinitialize window hash in order
    # to use last reading position on page refresh
    #
    window.location.hash = "##{id}"

    ebook = new App.Models.Ebook _id: id
    new App.Views.EbookReader(
      model: ebook, user: App.current_user,
      el: $('body'), params: params
    ).render()

  App.messages = new App.Collections.Messages
  App.Store = new App.Models.OfflineStore(name: 'ebook_reader', success: init)

  $(window).on 'orientationchange', ()->
    orientation = if (Math.abs(window.orientation % 180) == 90) then 'landscape' else 'portrait'
    width = window.screen.width
    height = window.screen.height

    if orientation == 'landscape' && height > width
      [width, height] = [height, width]
    else if orientation == 'portrait' && width > height
      [width, height] = [height, width]

    App.messages.send
      type: "orientation:change"
      content: {width: width, height: height}

  unless /ipad/i.test(window.navigator.userAgent)
    $(window).on 'resize', ->
      App.messages.send
        type: "resize"
        content: {width: $(window).width(), height: $(window).height()}


  # If Sticky fail to connect app is not started
  # FIXME :
  # * Fork Sticky to add an event in this case ?
  # * Force initialisation after an arbitrary number of seconds ?
  setTimeout ->
      init() unless App.Store
    , 3000
