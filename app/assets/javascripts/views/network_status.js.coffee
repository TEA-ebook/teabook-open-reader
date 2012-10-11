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



class App.Views.NetworkStatus extends Backbone.View
  tagName: 'span'

  initialize: ->
    @model = new App.Misc.NetworkStatus()
    $('body').on 'offline online', =>
      @updateNetworkStatus()


  render: ->
    # TODO: remove template if isn't necessary
    # @$el.html SMT['network_status']
    @updateNetworkStatus()
    @

  updateNetworkStatus: ->
    if App.onLine
      $('.onlyOnline').css visibility: 'visible'
      @$el.html('Online')
        .removeClass 'offline'
    else
      $('.onlyOnline').css visibility: 'hidden'
      @$el.html('Offline')
        .addClass 'offline'

