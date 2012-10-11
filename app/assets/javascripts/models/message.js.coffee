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



class App.Models.Message extends Backbone.Model

  initialize: (attrs)->
    @data = attrs.data
    @target = attrs.target
    @domain = attrs.domain
    @source = attrs.source || window

  send: ->
    @target.postMessage @data, @domain


class App.Models.ReceiveMessage extends App.Models.Message

  reply: (data)=>
    @source.postMessage data, @domain

class App.Collections.Messages extends Backbone.Collection

  register: (target, domain)->
    @target = target
    @domain = domain
    addEventListener 'message', @receive

  send: (data)=>
    m = new App.Models.Message data: data, target: @target, domain: @domain
    m.send()

  receive: (e)=>
    m = new App.Models.ReceiveMessage e
    unless m.data.type
      @trigger 'receive', m
    else
      @trigger "receive:#{m.data.type}", m.data.content
