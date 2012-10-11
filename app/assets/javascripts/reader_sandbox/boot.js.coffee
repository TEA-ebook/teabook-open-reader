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

  App.messages = new App.Collections.Messages
  App.messages.register parent, '*'
  App.messages.send type: "sandbox:ready"

  App.messages.on 'receive:initialize', (m)->
    ebook = new App.Models.Ebook m
    new App.Views.EbookReaderSandbox(model: ebook, user: App.current_user, el: $ 'body').render()

