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

  App.current_user = new App.Models.User _id: $('body').data('userid')
  App.bookstore = $('body').data('bookstore') || 'all'

  $('.networkStatus').html new App.Views.NetworkStatus().render().el

  new App.Misc.AppcacheLoader if $('body').data('userid')

  if $('body').hasClass 'epubs_index'

    init = ->
      ebooks = new App.Views.Ebooks
        collection: new App.Collections.Ebooks()
      $('.content').html ebooks.el

    App.Store = new App.Models.OfflineStore(name: 'ebook_reader', success: init)

    # If Sticky fail to connect app is not started
    # FIXME :
    # * Fork Sticky to add an event in this case ?
    # * Force initialisation after an arbitrary number of seconds ?
    # * I'm not sure but I think it's possible to use _.defer
    setTimeout ->
        init() unless App.Store
      , 2000

    # Help modal
    $('#help').html new App.Views.HelpLibrary().render().el

  else
    # Help modal
    $('#help').html new App.Views.HelpGeneric().render().el
