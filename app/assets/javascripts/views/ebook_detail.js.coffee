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



class App.Views.EbookDetail extends Backbone.View
  tagName: 'section'
  className: 'modal detailsPanel'

  tabsList: ['preview', 'toc']

  events:
    'click ul.tabs a': 'openTabHandler'

  initialize: (options)->
    @reader = options.reader

  render: =>
    @$el.html SMT['ebook/detail'] @model.toJSON()
    @$el.attr('id', "details#{@model.id}").hide()
    @tabs = []
    @tabs['preview'] = new App.Views.EbookPreview(model: @model)
    @$('#preview').html @tabs['preview'].render().el
    @tabs['toc'] = new App.Views.EbookToc(model: @model, el: @$('#toc'), reader: @reader)
    @$('#toc').hide()
    @

  openTabHandler: (e)->
    e.preventDefault()
    @openTab $(e.currentTarget).data('target')

  openTab: (current)->
    for tab in _.without(@tabsList, current)
      @$("##{tab}").hide()
    @$("##{current}").show()
    @tabs[current].trigger 'load'
    @$("header a[data-target!='#{current}']").parent().removeClass('active')
    @$("header a[data-target='#{current}']").parent().addClass('active')

