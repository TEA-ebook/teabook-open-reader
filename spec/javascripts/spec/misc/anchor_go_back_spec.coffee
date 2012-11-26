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



describe 'App.Misc.AnchorGoBack', ->

  it 'should be defined', ->
    expect(App.Misc.AnchorGoBack).toBeDefined()

  beforeEach ->
    @locus = 'locus'
    @getPlace = {
      getLocus: ->

    }
    spyOn(@getPlace, 'getLocus').andReturn(@locus)
    @reader = {
      getPlace: ->
        @getPlace
      moveTo: ->
    }
    spyOn(@reader, 'getPlace').andReturn(@getPlace)
    spyOn(@reader, 'moveTo')

    @goBackLink = {
      hide: ->
      show: ->
    }
    spyOn @goBackLink, 'hide'
    spyOn @goBackLink, 'show'

    @id = 'id'
    @goodHref = 'plop#id'
    @badHref = 'plop#bad'

    @anchorGoBack = new App.Misc.AnchorGoBack @reader, @goBackLink

  it 'must hide the go back link', ->
    expect(@goBackLink.hide.calls.length).toEqual(1)

  it 'must have an empty stack when created', ->
    expect(@anchorGoBack.linkStack.length).toEqual(0)

  describe ', when follow a link,', ->
    it 'must get the current locus', ->
      @anchorGoBack.followLinkFrom @id
      expect(@getPlace.getLocus.calls.length).toEqual(1)

    it 'must push an item in the stack', ->
      @anchorGoBack.followLinkFrom @id
      expect(@anchorGoBack.linkStack.length).toEqual(1)

    it 'must store current locus and source id in the stack', ->
      @anchorGoBack.followLinkFrom @id
      last = @anchorGoBack.linkStack[@anchorGoBack.linkStack.length - 1]
      expect(last.position).toEqual(@locus)
      expect(last.srcid).toEqual(@id)

    it 'must show the go back link', ->
      @anchorGoBack.followLinkFrom @id
      expect(@goBackLink.show.calls.length).toEqual(1)

  describe ', when try to go back,', ->
    beforeEach ->
      @goBackLink.hide.reset()

    it 'must hide the link when stack is yet empty', ->
      @anchorGoBack.go()
      expect(@goBackLink.hide.calls.length).toEqual(1)

    it 'must hide the link when stack has one element', ->
      @anchorGoBack.followLinkFrom @id
      @anchorGoBack.go()
      expect(@goBackLink.hide.calls.length).toEqual(1)

    it 'must not hide the link when stack is more than 2', ->
      @anchorGoBack.followLinkFrom @id
      @anchorGoBack.followLinkFrom @id
      @anchorGoBack.go()
      expect(@goBackLink.hide.calls.length).toEqual(0)

    it 'must pop the last link', ->
      @anchorGoBack.followLinkFrom @id
      stackLength = @anchorGoBack.linkStack.length
      @anchorGoBack.go()
      expect(@anchorGoBack.linkStack.length).toEqual(stackLength - 1)

    it 'must move to the last position', ->
      @anchorGoBack.followLinkFrom @id
      @anchorGoBack.go()
      expect(@reader.moveTo.calls.length).toEqual(1)
      expect(@reader.moveTo.mostRecentCall.args[0]).toEqual(@locus)

  describe ', when ask link to follow is last origin,', ->

    it 'must return false if no link was follow', ->
      expect(@anchorGoBack.can(@goodHref)).toEqual(false)

    it 'must return false if href not match with last id', ->
      @anchorGoBack.followLinkFrom @id
      expect(@anchorGoBack.can(@badHref)).toEqual(false)

    it 'must return true if href match with last id', ->
      @anchorGoBack.followLinkFrom @id
      expect(@anchorGoBack.can(@goodHref)).toEqual(true)
