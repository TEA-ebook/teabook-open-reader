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



describe 'App.Collections.Ebooks', ->

  beforeEach ->
    App.current_user = new App.Models.User(_id: 42)
    @model = new App.Collections.Ebooks()
    @xhr = new Response()
    # FIXME dirty, use real mock
    App.Store = {
      get: ->
      set: ->
      remove: ->
    }

  it 'should be defined', ->
    expect(App.Collections.Ebooks).toBeDefined()

  it 'should have url', ->
    expect(@model.url()).toBe '/ebook/epubs.json'

  describe 'offline sync', ->
    beforeEach ->
      @store = sinon.mock(App.Store)
    afterEach ->
      @store.restore()

    it 'should have generic offlineKey', ->
      App.bookstore = undefined
      expect(@model.offlineKey()).toEqual "#{App.current_user.id}:ebooks:all"

    it 'should have bookstore specific offlineKey', ->
      App.bookstore = 'tea'
      expect(@model.offlineKey()).toEqual "#{App.current_user.id}:ebooks:tea"

    it 'should set cache when reading online', ->
      App.onLine = true
      @xhr.with(@model).queue()
      @store.expects('set').withArgs(@model.offlineKey())
      @model.fetch()
      @xhr.server.respond()
      @store.verify()

    it 'should get cache when reading offline', ->
      App.onLine = false
      @xhr.with(@model).queue()
      @store.expects('get').withArgs(@model.offlineKey()).callsArgWith(1, [{foo: 'bar'}])
      reset_spy = sinon.spy(@model, 'reset')
      @model.fetch()
      @xhr.server.respond()
      @store.verify()
      expect(reset_spy).toHaveBeenCalledWith([{foo: 'bar'}])

    describe 'order', ->

      it 'should order ebook by title by default', ->
        @model.add BackboneFactory.create 'ebook', ->
          title: 'Z book'
        @model.add BackboneFactory.create 'ebook', ->
          title: 'A book'
        expect(@model.models[0].get 'title').toBe 'A book'
        expect(@model.models[1].get 'title').toBe 'Z book'

      it 'should allow to force order on authors (main one)', ->
        @model.order = 'author'
        @model.add BackboneFactory.create 'ebook', ->
          title: 'A book'
          authors: [
            {author_name: 'Molière', main: true},
            {author_name: 'Rimbaud', main: false},
          ]
        @model.add BackboneFactory.create 'ebook', ->
          title: 'Z book'
          authors: [
            {author_name: 'Baudelaire', main: true},
            {author_name: 'Voltaire', main: false},
          ]
        expect(@model.models[0].get 'title').toBe 'Z book'
        expect(@model.models[1].get 'title').toBe 'A book'

      it 'should allow to force order on publisher', ->
        @model.order = 'publisher'
        @model.add BackboneFactory.create 'ebook', ->
          title: 'A book'
          publisher: {
            publisher_name: "Z publisher"
          }
        @model.add BackboneFactory.create 'ebook', ->
          title: 'Z book'
          publisher: {
            publisher_name: "A publisher"
          }
        expect(@model.models[0].get 'title').toBe 'Z book'
        expect(@model.models[1].get 'title').toBe 'A book'

