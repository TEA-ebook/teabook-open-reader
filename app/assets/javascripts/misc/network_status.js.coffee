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



class App.Misc.NetworkStatus

  constructor: ->
    App.onLine = $('body').data('online')
    @checkNetwork()
    setInterval @checkNetwork, 10000

  checkNetwork: ->
    $.ajax(
      "/network_status",
      cache: false,
      timeout: 2000
    ).done(->
      if App.onLine != true
        App.onLine = true
        $('body').trigger('online')
    ).error ->
      if App.onLine != false
        App.onLine = false
        $('body').trigger('offline')
