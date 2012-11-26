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



class App.Views.EbookReaderSandbox extends Backbone.View
  events:
    'click .layout':      'switchLayout'
    'click .annotate':    'toggleAnnotate'
    'click .details':     'toggleDetails'
    'click .settings':    'toggleSettings'
    'click .library':     'backToLibrary'
    'click .goback':      'goBackLink'
    'mouseover #reader':  'showMenu'
    'keydown':            'keydown'

  initialize: ->
    @textLocator = new App.Misc.TextLocator
    @reader_options =
      flipper: App.Flippers.DoublePages
      panels: App.Panels.Arrows
    App.messages.on 'receive:orientation:change', @changeOrientation
    App.messages.on 'receive:resize', _.throttle(@sizeChanged, 1000)
    App.messages.on 'receive:keydown', @keyhandler
    @model.set 'sandbox', true

  keydown: (event) =>
    @keyhandler event.keyCode

  keyhandler: (keycode) =>
    return unless @flipper
    action = App.Misc.KeyCodes[keycode]
    nbPages = if @flipper.onSinglePage() then 1 else 2
    switch action
      when 'left'  then @flipper.moveTo direction: -nbPages
      when 'right' then @flipper.moveTo direction:  nbPages

  showMenu: =>
    unless @lockMenu
      @lockMenu = true
      @$('#reader').addClass 'showMenu'
      setTimeout =>
          @$('#reader').removeClass 'showMenu'
          @lockMenu = false
        , 4000

  bindEventsInIframes: =>
    for iframe in $('iframe')
      body = $($(iframe).contents().get(0).body)
      body.keydown @keydown
      body.hammer().bind 'tap', @showMenu

  render: ->
    @$el.html SMT['ebook/reader_sandbox'] @model.toJSON()
    @initializeReader()
    @

  changeOrientation: (dimensions)=>
    @flipper.redraw(dimensions) if @reader && @flipper

  initializeReader: =>
    @reader_options.rtl = @model.get('direction') == "rtl"
    if @model.get('readingPosition').position()
      # console.log('setting reading position', @model.get('readingPosition').position())
      @reader_options.place = @model.get('readingPosition').position()
    @reader = Monocle.Reader 'reader', @model, @reader_options, @configureReader

  configureReader: (reader)=>
    @flipper = @reader.properties.flipper

    # Scrubber (bottom slider)
    scrubber = new App.Controls.Scrubber reader
    reader.addControl scrubber

    # Percent of book
    locationDisplay = new App.Controls.Location reader
    reader.addControl locationDisplay, 'standard'

    # Reader Menu
    menuControl = {}
    menuControl.createControlElements = =>
      @menuControl = new App.Views.EbookReaderMenu()
      @menuControl.render().el
    reader.addControl menuControl, 'standard'

    # Settings
    @settingsPanel = new App.Views.SettingsPanel(reader: @reader)
    @$el.append @settingsPanel.render().el

    # Go back link
    @anchorGoBack = new App.Misc.AnchorGoBack(@reader, $('a.menu.goback'))
    # Anchor binder
    @anchorBinder = new App.Misc.AnchorBinder(@reader, @, @anchorGoBack)
    reader.listen 'monocle:loaded', @anchorBinder.process
    reader.listen 'monocle:componentchange', @anchorBinder.process

    # Bind iPad click to show Menus
    reader.listen 'monocle:loaded', @bindEventsInIframes
    reader.listen 'monocle:componentmodify', @bindEventsInIframes

    # Bind specific events to our view
    reader.listen 'monocle:loaded', @bindPlayerEvents

    # Show visual marker for reading position
    reader.listen 'monocle:loaded', @updateReadingPosition

    # Update the layout label
    reader.listen 'monocle:loaded', @updateSwitchLayoutLabel

    # Hide loader
    reader.listen 'monocle:loaded', @hideLoader

    # Prevent from printing Ebook with DRM
    unless @model.printable()
      reader.listen 'monocle:loaded', @protectContent
      reader.listen 'monocle:componentmodify', @protectContent

  bindPlayerEvents: =>
    # Have to unbind player events to avoid multiple binds on it
    @reader.deafen 'monocle:turn', @saveReadingPosition
    @reader.listen 'monocle:turn', @saveReadingPosition

  orientationChanged: (dimensions)=>
    @flipper.redraw(dimensions) if @reader && @flipper

  sizeChanged: (dimensions)=>
    @flipper.redraw(dimensions) if @reader && @flipper

  switchLayout: (e)=>
    e.preventDefault()
    @flipper.toggleForceSinglePage()
    @updateSwitchLayoutLabel()

  updateSwitchLayoutLabel: =>
    if @flipper.properties.forceSinglePage
      text = "Permettre l'affichage sur deux pages"
    else
      text = "Forcer l'affichage sur une seule page"
    @$('.layout').text text
    @$('.layout').attr 'title', text

  toggleSettings: =>
    ## Strange bug on dragDealer when using show/hide :/
    $('.settingsPanel').css
      visibility: 'visible'
    $('.settingsPanel').modal('show')

  toggleDetails: =>
    unless $('.detailsPanel').get(0)
      @detailsPanel = new App.Views.EbookDetail(model: @model, reader: @reader)
      @$el.append @detailsPanel.render().el
    @detailsPanel.openTab('preview')
    $('.detailsPanel').modal('show')
    @hideSettings()
    @

  hideSettings: ->
    $('.settingsPanel').modal('hide')

  toggleAnnotate: ->
    if @$('.annotatePanel').get(0)
      @$('.annotatePanel').remove()
    else
      annotation = new App.Views.Annotate(model: @currentPageAnnotation()).render().el
      @$el.append annotation
      @

  currentComponentName: ->
    @reader.getPlace().componentId()

  currentPageAnnotation: ->
    # TODO: Actually return the page-specific annotation
    @annotations ||= {}
    key = "#{@currentLocus().componentId}#{@currentLocus().percent}"
    return @annotations[key] if @annotations[key]
    @annotations[key] = new App.Models.Annotation(@model.id, @currentComponentName(), @rangeOfCurrentPage(), '')

  contentFrames: =>
    @$('iframe.monelem_component').map (i, element)->
      element.m.pageDiv.m.activeFrame

  topMostLeftFrame: =>
    @flipper.visiblePages()[0]

  topMostRightFrame: =>
    # FIXME this doesn't work when we show a single page
    @flipper.visiblePages()[1]

  # FIXME: Very crude approximation of a Range look-alike for the current page
  rangeOfCurrentPage: ->
    startContainer: @textLocator.firstVisibleElement(@topMostLeftFrame()), startOffset: 0,
    endContainer: @textLocator.firstVisibleElement(@topMostRightFrame()),   endOffset: 0

  currentLocus: ->
    @reader.getPlace().getLocus()

  updateReadingPosition: ()=>
    data =
      pages: @flipper.visiblePages()
      locus: @currentLocus()
      percentage: this.reader.getPlace().percentageOfBook()
    @model.get('readingPosition').updatePosition data

  saveReadingPosition: ()=>
    @updateReadingPosition()
    App.messages.send
      type: 'readingPosition:save'
      content: @model.get('readingPosition').toJSON()

  protectContent: (e)=>
    @preventPrint()
    @preventSelection()

  preventPrint: =>
    for iframe in $('iframe')
      tag = $('<style>', type: 'text/css', media: 'print', text: "
        body{
          display: none !important;
        }
      ")
      $($(iframe).contents().get(0).head).append tag

  preventSelection: =>
    for iframe in $('iframe')
      tag = $('<style>', type: 'text/css', media: 'all', text: "
        body{
          -webkit-touch-callout: none;
          -webkit-user-select: none;
          -moz-user-select: none;
          -khtml-user-select: none;
          -o-user-select: none;
          -ms-user-select: none;
          user-select: none;
        }
      ")
      $($(iframe).contents().get(0).head).append tag

  hideLoader: =>
    @$('.loader').hide()

  backToLibrary: =>
    App.messages.send
      type: 'navigate'
      content: '/ebook/epubs'

  goBackLink: (e) =>
    e.preventDefault()
    @anchorGoBack.go()
