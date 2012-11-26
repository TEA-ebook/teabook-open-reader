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

# The AnchorGoBack allow to go to the previous reading position
# after click a link, as a footnote.
class App.Misc.AnchorGoBack
  constructor: (@reader, @goBackLink) ->
    @linkStack = []
    @goBackLink.hide()

  # Go back using the filled link stack
  # and hide the button stack is empty
  go: () ->
    if @linkStack.length > 0
      last = @linkStack.pop()
      @reader.moveTo last.position
    if @linkStack.length == 0
      @goBackLink.hide()

  # Indicate the GoBack object the user follow a link
  # The id is saved to be able to return to the real
  # initial position even if the user click a real
  # back link.
  followLinkFrom: (id) ->
    currentLocus = @reader.getPlace().getLocus()
    @linkStack.push(position: currentLocus, srcid: id)
    @goBackLink.show()

  # Check if the link the user wants to follow
  # return to the last position saved in the stack.
  # If yes, you can call a `go()` just after that to
  # allow to user to be positionned just before clicking
  # the first link and not move to the anchor position.
  can: (href) ->
    return false if @linkStack.length == 0
    last = @linkStack[@linkStack.length - 1]
    matches = href.match /^.*#(.+)$/
    return matches[1] == last.srcid
