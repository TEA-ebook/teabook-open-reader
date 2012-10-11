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



class App.Views.EbookToc extends Backbone.View

  events:
    'click .chapter': 'clickChapter'

  initialize: (options)->
    @reader = options.reader
    @rendered = false
    # If chapters already present, render view
    if @model.get('chapters').length
      @render()
    # Else wait for load event
    else
      @.on 'load', =>
        unless @rendered
          @model.fetch
            success: @render
            error: =>
              @$el.html 'Sommaire non disponible'

  clickChapter: (e)->
    e.preventDefault()
    # When in reader, we only want to go to specified chapter
    if @reader
      @reader.skipToChapter $(e.currentTarget).data 'chapter-src'
      @$el.closest('.modal').modal 'hide'
    # When in library, we want to open reader on specified chapter
    else
      window.location = $(e.currentTarget).attr 'href'

  render: =>
    @$el.html SMT['ebook/toc'] chapters: @model.chaptersWithLinksJSON()
    @rendered = true
    @
