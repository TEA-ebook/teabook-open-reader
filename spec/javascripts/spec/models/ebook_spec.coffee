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



describe 'App.Models.Ebook', ->

  beforeEach ->
    App.current_user = new App.Models.User(_id: '4fdf4d2793a71e5f66000001')
    @model = new App.Models.Ebook(_id: '4fdf4d2793a71e5f66000002')
    @xhr = new Response()
    # FIXME dirty, use real mock
    App.Store = {
      get: ->
      set: ->
      remove: ->
    }

  afterEach ->
    @xhr.server.restore()

  it 'should be defined', ->
    expect(App.Models.Ebook).toBeDefined()

  it 'should have offlineKey', ->
    expect(@model.offlineKey()).toEqual "#{App.current_user.id}:ebooks:#{@model.id}"

  describe 'fetch', ->
    beforeEach ->
      @store = sinon.mock(App.Store)
      @loadComponentsStub = sinon.stub @model, 'loadComponentsFromStore', =>
        @model.trigger 'loadFromStore:success'
    afterEach ->
      @store.restore()
      @loadComponentsStub.restore()

    it 'should loadComponentsFrom Store if Ebook is available offline', ->
      spy = sinon.spy()
      @store.expects('get').withArgs(@model.offlineKey()).callsArgWith(1, {foo: 'bar'})
      @model.fetch(success: spy)
      expect(spy).toHaveBeenCalled()

  describe 'loadComponentsFromStore', ->

    it 'should trigger loadFromStore:success when all components are loaded from offline store', ->
      spy = sinon.spy()
      @model.on 'loadFromStore:success', spy
      @loadComponentsStub = sinon.stub @model.get('components'), 'loadFromStore', =>
        @model.get('components').trigger 'loadFromStore:components:success'
      @model.loadComponentsFromStore()
      expect(spy).toHaveBeenCalled()

  describe 'checkOffline method', ->

    describe 'when App.Store is not defined', ->
      beforeEach ->
        App.Store = null

      it 'should set offline attribute to false and trigger "offline:status"', ->
        @model.set 'offline', true
        eventSpy = sinon.spy()
        @model.on 'offline:status', eventSpy
        @model.checkOffline()
        expect(eventSpy).toHaveBeenCalled()
        expect(@model.get 'offline').toBe false

    describe 'when App.Store is defined', ->
      beforeEach ->
        @store = sinon.mock(App.Store)
      afterEach ->
        @store.restore()

      describe 'but ebook not already stored', ->
        beforeEach ->
          @store.expects('get').withArgs(@model.offlineKey()).callsArgWith(1, false)

        it 'should set offline attribute to false and trigger "offline:status"', ->
          @model.set 'offline', true
          eventSpy = sinon.spy()
          @model.on 'offline:status', eventSpy
          @model.checkOffline()
          expect(eventSpy).toHaveBeenCalled()
          expect(@model.get 'offline').toBe false
          @store.verify()

      describe 'and ebook already stored', ->
        beforeEach ->
          @store.expects('get').withArgs(@model.offlineKey()).callsArgWith(1, {foo: 'bar'})

        it 'should set offline attribute to true, retreive model data and trigger "offline:status"', ->
          @model.set 'offline', false
          @model.set 'chapters', []
          @model.set 'components', []
          eventSpy = sinon.spy()
          @model.on 'offline:status', eventSpy
          @model.checkOffline()
          expect(eventSpy).toHaveBeenCalled()
          expect(@model.get 'offline').toBe true
          expect(@model.get 'foo').toBe 'bar'
          @store.verify()

  describe 'download', ->
    beforeEach ->
      @model.set 'offline', false

    describe 'when App.Store is not defined', ->
      beforeEach ->
        App.Store = null

      it 'should trigger download:failed', ->
        spy = sinon.spy()
        @model.on 'download:failed', spy
        @model.download()
        expect(spy).toHaveBeenCalled()

    describe 'when App.Store is defined', ->
      beforeEach ->
        @store = sinon.mock(App.Store)
      afterEach ->
        @store.restore()

      describe ', API calls succeed', ->
        beforeEach ->
          @xhr.with(@model).queue()
          @componentsFetchStub = sinon.stub @model.get('components'), 'chunkFetch', =>
            @model.get('components').trigger 'storeOffline:components:success'
        afterEach ->
          @componentsFetchStub.restore()

        describe 'but store fail to set data', ->
          it 'should trigger download:started and trigger download:failed', ->
            spy = sinon.spy()
            @model.on 'download:started', spy
            @model.on 'download:failed', spy
            @store.expects('get').withArgs(@model.offlineKey()).callsArgWith(1, false)
            @store.expects('set').withArgs(@model.offlineKey()).callsArgWith(2, false)
            @model.download()
            @xhr.server.respond()
            expect(spy).toHaveBeenCalledTwice()
            expect(@model.get 'offline').toBe false
            @store.verify()

        describe 'and store succeed to set data', ->

          it 'should trigger download:started, set cache and trigger download:complete', ->
            spy = sinon.spy()
            @model.on 'download:started', spy
            @model.on 'download:complete', spy
            @store.expects('get').withArgs(@model.offlineKey()).callsArgWith(1, false)
            @store.expects('set').withArgs(@model.offlineKey()).callsArgWith(2, {foo: 'bar'})
            @model.download()
            @xhr.server.respond()
            expect(spy).toHaveBeenCalledTwice()
            expect(@model.get 'offline').toBe true
            @store.verify()


  describe 'remove', ->
    beforeEach ->
      @model.set 'offline', true

    describe 'when App.Store is not defined', ->
      beforeEach ->
        App.Store = null

      it 'should trigger remove:failed', ->
        spy = sinon.spy()
        @model.on 'remove:failed', spy
        @model.remove()
        expect(spy).toHaveBeenCalled()

    describe 'when App.Store is defined', ->
      beforeEach ->
        @store = sinon.mock(App.Store)
        @componentsFetchStub = sinon.stub @model.get('components'), 'removeFromStore', =>
          @model.get('components').trigger 'removeFromStore:components:success'
      afterEach ->
        @componentsFetchStub.restore()
        @store.restore()

      describe 'but store fail to remove data', ->
        it 'should trigger remove:failed', ->
          spy = sinon.spy()
          @model.on 'remove:failed', spy
          @store.expects('remove').withArgs(@model.offlineKey()).callsArgWith(1, false)
          @model.remove()
          expect(spy).toHaveBeenCalledOnce()
          expect(@model.get 'offline').toBe true
          @store.verify()

      describe 'and store succeed to remove data', ->

        it 'should trigger remove:success', ->
          spy = sinon.spy()
          @model.on 'remove:success', spy
          @store.expects('remove').withArgs(@model.offlineKey()).callsArgWith(1, true)
          @model.remove()
          expect(spy).toHaveBeenCalledOnce()
          expect(@model.get 'offline').toBe false
          @store.verify()

  describe 'Monocle interface', ->
    beforeEach ->
      @missingComponent = new App.Models.Component({_id: '3', src: '3.html'})
      @model.set 'components', new App.Collections.Components([
        {_id: '1', src: '1.html', content: 'Foo bar'},
        {_id: '2', src: '2.html', content: 'Hello World'}
        @missingComponent
      ])

    describe 'getComponents', ->

      it 'should map src attributes of components', ->
        expect(@model.getComponents()).toEqual ['1.html', '2.html', '3.html']

    describe 'getComponent', ->
      beforeEach ->
        window.TeaEncryption = undefined

      describe 'component is in cache', ->

        it 'return call given callback with content of the given component', ->
          spy = sinon.spy()
          @model.getComponent('2.html', spy)
          expect(spy).toHaveBeenCalledWith('Hello World')

      describe 'component is not in cache', ->
        beforeEach ->
          @xhr.with(@missingComponent).queue()

        it 'return call given callback with content of the given component', ->
          spy = sinon.spy()
          @model.getComponent('3.html', spy)
          @missingComponent.set 'content', 'Hello World again'
          @xhr.server.respond()
          expect(spy).toHaveBeenCalledWith('Hello World again')
