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



# The AnchorBinder parses a Monocle component content in order to detect
# internal links and bind a Monocle moveTo to the click event.

class App.Misc.AnchorBinder
  constructor: (@reader, @view, @anchorGoBack) ->

  process: ()=>
    _.each @view.contentFrames(), (contentFrame)=>
      document = $(contentFrame.contentDocument)

      links = document.find('a')

      for anchor, i in links
        link = $(anchor)
        locus = @locusOfChapter(link.attr('href'))
        if @linkIsNotAlreadyProcessed(link)
          if locus
            @bindInternalLink link, locus
          else
            @bindExternalLink link
          @markLinkAsProcessed link

  locusOfChapter: (link)->
    @reader.getBook().locusOfChapter(link) if link

  linkIsNotAlreadyProcessed: (link)->
    ! link[0].processed

  markLinkAsProcessed: (link)->
    # $(link).css('color', 'green')
    link[0].processed = true

  bindInternalLink: (link, locus)->
    link.on 'click', (event)=>
      event.preventDefault()
      if @anchorGoBack.can(link[0].href)
        # go back using the "real" last position
        # and not the position of the anchor
        @anchorGoBack.go()
      else
        # just follow the link
        @anchorGoBack.followLinkFrom link[0].id
        @reader.moveTo locus

  bindExternalLink: (link)->
    link.on 'click', (event)->
      event.preventDefault()
      href = $(event.target).closest('a')[0].href
      App.messages.send
        type: "openExternalLink"
        content: href
