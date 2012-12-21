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



##
# The DoublePages flipper is a very important part of the reader. It's a
# Monocle module that display the content of the ebook on one or two pages.
#
# It decides to display one or two pages according to the orientation of the
# screen, the user preferences and the ebook data. In particular, it means
# that fixed layout rules of epub3 are implemented here. And they bring their
# own special cases. Lots of them!
#
# So, you should avoir to modify this file. But if you have to, be brave and
# read the comments to avoid some pitfalls.
#
App.Flippers.DoublePages = (reader) ->

  # Initialize the reader
  initialize = ->
    p.reader = reader
    p.reader.listen "monocle:componentchanging", showWaitControl
    p.availableScales = [1, 1.5, 2, 3, 4]
    Monocle.defer ->
      showWaitControl()
      reader.dom.find('page', p.leftIndex).className = 'monelem_page left'
      reader.dom.find('page', p.rightIndex).className = 'monelem_page right'
      reader.dom.find('page', p.leftNextIndex).className = 'monelem_page leftNext'
      reader.dom.find('page', p.rightNextIndex).className = 'monelem_page rightNext'
      setOrientationAndSizes()

  # Redraw the one or two pages (after the window has been resized for example)
  redraw = (dimensions)->
    locus = p.reader.getPlace().getLocus()
    setOrientationAndSizes(dimensions)
    for page in [leftPage(), rightPage(), leftNextPage(), rightNextPage()]
      page.m.activeFrame.m.component = null if page.m.activeFrame
    moveTo locus

  # Defines the orientation and sizes of the reader to optimize the place taken on screen
  setOrientationAndSizes = (dimensions)->
    # don't use reader.resized() because we want to force width/height page ratio
    ratio = 0.80
    if dimensions
      winh = dimensions.height
      winw = dimensions.width
    else
      winh = $(window).height()
      winw = $(window).width()

    # Choose orientation
    if winh / winw > 1.0
      p.orientation = "portrait"
      enterPortrait()
    else
      ratio *= 2  # In landscape, we'll try to show 2 pages
      p.orientation = "landscape"
      leavePortrait()

    # Choose dimensions
    if winw > winh * ratio
      height = winh * 0.95  # For margins
      width  = height * ratio
    else
      width = winw * 0.95  # For margins
      height = width / ratio

    p.readerWidth = width
    p.readerHeight = height

    # Apply the dimensions
    r = document.getElementById('reader')
    r.style.width = "#{width}px"
    r.style.height = "#{height}px"


  # Fire the on/off interactive event
  interactiveMode = (bState) ->
    p.reader.dispatchEvent "monocle:interactive:" + (if bState then "on" else "off")

  applyScaleAndTranslate = (page, sheaf, scale, x, y) ->
    transform = "scale(#{scale})"
    if scale > 1
      transform = "#{transform} translateX(#{x}px) translateY(#{y}px)"

    page.style.overflow = 'hidden'
    el = getFrameBody sheaf
    el.style.WebkitTransform = transform
    el.style.MozTransform = transform
    el.style.transform = transform

    el.style.width = "#{page.offsetWidth}px"
    el.style.height = "#{page.offsetHeight}px"

  getSheaf = (page) ->
      page.getElementsByClassName('monelem_sheaf')[0]

  getFrameBody = (sheaf) ->
    sheaf.getElementsByTagName('iframe')[0].contentDocument.body

  checkOnSinglePageAndReset = () ->
    # zoom is allowed when there is a single page, for whatever reason
    pages = visiblePages()
    return true if pages.length == 1
    # if more than one page, reset zoom and translation
    page = leftPage()
    sheaf = getSheaf(page)
    applyScaleAndTranslate page, sheaf, 1, 0, 0
    false

  # be ready for the interactive mode of the i-mode panels
  listenForInteraction = (panelClass) ->
    interactiveMode true
    interactiveMode false
    unless typeof panelClass is "function"
      panelClass = k.DEFAULT_PANELS_CLASS
      console.warn "Invalid panel class."  unless panelClass
    q = (action, panel, x, y, direction) ->
      dir = k[direction]
      dir = -dir if p.reader.properties.rtl
      if action is "lift"
        lift dir, x
      else if action is "release"
        release dir, x

    getScaleFor = (el) ->
      expr = /scale(3d)?\((-?[0-9.]+)\)/
      if el.style.transform
        matches = el.style.transform.match expr
        return 1 unless matches
        return parseFloat matches[2]
      if el.style.MozTransform
        matches = el.style.MozTransform.match expr
        return 1 unless matches
        return parseFloat matches[2]
      if el.style.WebkitTransform
        matches = el.style.WebkitTransform.match expr
        return 1 unless matches
        return parseFloat matches[2]
      return 1

    getTranslationFor = (el, type) ->
      expr = new RegExp "translate#{type}\\((-?[0-9.]+)px\\)"
      if el.style.transform
        matches = el.style.transform.match expr
        return 0 unless matches
        return parseFloat matches[1]
      if el.style.MozTransform
        matches = el.style.MozTransform.match expr
        return 0 unless matches
        return parseFloat matches[1]
      if el.style.WebkitTransform
        matches = el.style.WebkitTransform.match expr
        return 0 unless matches
        return parseFloat matches[1]
      return 0
      

    z = (panel, e, direction) ->
      page = leftPage()
      sheaf = getSheaf(page)
      currentScale = getScaleFor getFrameBody sheaf
      scaleFactor = 1 + Math.log(e.scale) / (8 * Math.log(10))
      newScale = currentScale * scaleFactor
      newScale = Math.max p.availableScales[0], newScale
      newScale = Math.min newScale, p.availableScales[-1..][0]
      body = getFrameBody sheaf
      applyScaleAndTranslate page, sheaf, newScale, getTranslationFor(body, 'X'), getTranslationFor(body, 'Y')

    m = (panel, e) ->
      page = leftPage()
      sheaf = getSheaf(page)
      scale = getScaleFor getFrameBody sheaf
      currentPosition = e.position
      dx = currentPosition.x - p.initialPosition.x + p.initialDelta.x
      dy = currentPosition.y - p.initialPosition.y + p.initialDelta.y
      applyScaleAndTranslate page, sheaf, scale, dx, dy

    p.panels = new panelClass(API,
      start: (panel, e, direction) ->
        page = leftPage()
        sheaf = getSheaf(page)
        if direction != ""
          applyScaleAndTranslate page, sheaf, 1, 0, 0
          q "lift", panel, e.position.offsetX, e.position.offsetY, direction
          return
        return unless checkOnSinglePageAndReset()
        scale = getScaleFor getFrameBody sheaf
        return if scale <= 1
        p.translate = true
        body = getFrameBody sheaf
        p.initialDelta =
          x: getTranslationFor body, "X"
          y: getTranslationFor body, "Y"
        p.initialPosition = e.position

      move: (panel, e, direction) ->
        if direction != ""
          turning k[direction], e.position.offsetX
          return
        return unless checkOnSinglePageAndReset()
        return unless p.translate
        return if e.touches.length > 1
        m panel, e

      end: (panel, e, direction) ->
        if p.translate
          p.translate = false
          return
        p.translate = false
        if direction == ""
          p.reader.dispatchEvent "teabook:tap:middle"
        else
          q "release", panel, e.position.offsetX, e.position.offsetY, direction

      cancel: (panel, e, direction) ->
        return if direction == ""
        q "release", panel, e.position.offsetX, e.position.offsetY, direction

      transform: (panel, e, direction) ->
        return unless checkOnSinglePageAndReset()
        return if e.touches.length < 2
        z panel, e, direction

      transformend: (panel, e, direction) ->
        return unless checkOnSinglePageAndReset()
        z panel, e, direction

      doubletap: (panel, e, direction) ->
        return unless checkOnSinglePageAndReset()
        return unless direction == ""
        page = leftPage()
        sheaf = getSheaf(page)
        currentScale = getScaleFor getFrameBody sheaf
        scale = 1
        l = p.availableScales.length
        if currentScale > p.availableScales[l - 1] || currentScale < p.availableScales[0]
          scale = p.availableScales[0]
        else
          for i in [1...l]
            if p.availableScales[i - 1] <= currentScale < p.availableScales[i]
              scale = p.availableScales[i]
              break
        body = getFrameBody sheaf
        translateX = getTranslationFor body, 'X'
        translateY = getTranslationFor body, 'Y'
        applyScaleAndTranslate page, sheaf, scale, translateX, translateY
    )


  # Add a <div> for a page in the DOM
  addPage = (pageDiv) ->
    pageDiv.m.dimensions = new Monocle.Dimensions.Columns(pageDiv)
    Monocle.Styles.setX pageDiv, 0

  # Return the <div>s that are currently visibles on screen
  visiblePages = ->
    if onSinglePage() or p.centerMode or p.landscapeMode
      [leftPage()]
    else
      page for page in [leftPage(), rightPage()] when isVisible page

  # Find the page that is currently on the left/right of the screen or the one that will be there next
  findPage = (side, pos) ->
    # For some performance reasons, when an ebook must be read from right to left,
    # we use the "right" iframes to display "left" pages and vice versa!
    if p.reader.properties.rtl
      side = if side == "left" then "right" else "left"
    if p.activeIndex
      pos = if pos == "Next" then "" else "Next"
    p.reader.dom.find "page", p["#{side}#{pos}Index"]

  # Left and right pages are currently displayed on screen.
  leftPage = ->
    findPage "left", ""
  rightPage = ->
    findPage "right", ""

  # These are the prepared pages that will be displayed next when the user will move forward in the ebook
  leftNextPage = ->
    findPage "left", "Next"
  rightNextPage = ->
    findPage "right", "Next"

  # Move the next pages on top of the current pages
  flipPages = ->
    rightPage().style.zIndex = 1
    leftPage().style.zIndex = 1
    rightNextPage().style.zIndex = 2
    leftNextPage().style.zIndex = 2
    p.activeIndex = (p.activeIndex + 1) % 2

  # Return the place where we are in the ebook
  getPlace = (pageDiv) ->
    pageDiv = pageDiv or visiblePages()[0]
    (if pageDiv.m then pageDiv.m.place else null)

  # Is this page the cover of the ebook?
  # TODO in Monocle components, we should avoid to use jQuery
  isCover = (pageDiv) ->
    return false unless getPlace(pageDiv).onFirstPageOfBook()
    $(pageDiv).find('iframe').contents().find('body').text().match(/^\s*$/)

  # Remove margins (e.g. cover page)
  withMargin = (pageDiv) ->
    pageDiv.classList.remove('no_margin')

  # Add margins
  noMargin = (pageDiv) ->
    pageDiv.classList.add('no_margin')

  # For prepaginated content, we force the dimensions to the good ratio
  # and use a transform CSS property to adjust the zoom level.
  fixDimensions = (pageDiv, [width, height]) ->
    h = p.readerHeight
    w = if p.landscapeMode or onSinglePage() then p.readerWidth else p.readerWidth / 2
    zoom = if w * height > h * width then h / height else w / width
    scale = "scale(#{zoom})"
    pageDiv.style.WebkitTransform = scale
    pageDiv.style.MozTransform = scale
    pageDiv.style.transform = scale

    # Workaround for ipad bugs
    if navigator.userAgent.match /ipad/i
      pageDiv.m.activeFrame.style.width  = "#{width * zoom}px"
      pageDiv.m.activeFrame.style.height = "#{height * zoom}px"
      pageDiv.m.activeFrame.style.WebkitTransform = "scale(#{1 / zoom})"
      pageDiv.m.activeFrame.style.WebkitTransformOrigin = "top left"

  # Reset CSS rules for pages that were prepaginated
  resetDimensions = (pageDiv) ->
    pageDiv.style.WebkitTransform = null
    pageDiv.style.MozTransform = null
    pageDiv.style.transform = null


  # Take a <div> and fill it with the content at the given locus.
  # We need to know if the page is a left or right page for the page-spread properties
  # And when we are done, the callback function is called with the updated locus of this page
  loadPage = (pageDiv, side, locus, callback) ->
    showPage pageDiv  # XXX The page have to be visible, or Monocle can't load it
    p.reader.getBook().setOrLoadPageAt pageDiv, locus, (locus) ->
      if locus.layout == "pre-paginated" && locus.dimensions
        noMargin pageDiv
        fixDimensions pageDiv, locus.dimensions
      else if isCover pageDiv
        noMargin pageDiv
        resetDimensions pageDiv
      else
        withMargin pageDiv
        resetDimensions pageDiv
      pageDiv.m.dimensions.translateToLocus locus
      callback locus

  # Does this page is shown or blank?
  isABlankPage = (pageDiv, side, locus) ->
    if p.reader.properties.rtl
      other = side
    else
      other = if side == "left" then "right" else "left"
    reversed = if p.orientation == "landscape" then "portrait" else "landscape"
    return true if locus.orientation == "landscape"
    return true if locus.pageSpread == "center"
    return true if locus.spread == "none"
    return true if locus.spread == reversed
    return true if locus.pageSpread == other and locus.page == 1
    false

  # moveTo is one of the most important and complex functions in this file.
  #
  # We have three types of movement in pages: the simple forward move, the simple backward move
  # and the generic move to a locus. The first two are optimized: in most cases, only two of
  # the four iframes are modified. This function is the last move.
  moveTo = (locus, callback) ->
    # This function will be called when the two current pages are ready
    # to prepare the next two pages and then execute the callback
    fn = (locus) ->
      checkOnSinglePageAndReset()
      prepareNextPages locus, ->
        callback()  if typeof callback is "function"
        announceTurn()

    # First, we try to set the left page
    loadPage leftPage(), "left", locus, (locus) ->
      reversed = if p.orientation == "landscape" then "portrait" else "landscape"
      side = if reader.properties.rtl then "left" else "right"

      # Special case #1: landscape mode
      if locus.orientation == "landscape"
        showPage leftNextPage()
        enterLandscapeMode()
        fn getPlace(leftPage()).getLocus(direction: k.FORWARDS)
        return
      leaveLandscapeMode() if p.landscapeMode

      # Special case #2: center mode
      # Special case #3: single page
      if locus.pageSpread == "center" or onSinglePage()
        showPage leftNextPage()
        enterCenterMode()
        fn getPlace(leftPage()).getLocus(direction: k.FORWARDS)
        return
      leaveCenterMode() if p.centerMode

      # Special case #4: no synthetic spread
      #   => we hide the right page
      if locus.spread == "none" || locus.spread == reversed
        showPage leftNextPage()
        hidePage rightNextPage()
        hidePage rightPage()
        fn getPlace(leftPage()).getLocus(direction: k.FORWARDS)
        return

      # Special case #5: page-spread-right (left if rtl)
      #   => we load the same page on the right and then try to find the previous page for the left
      if locus.pageSpread == side and locus.page == 1
        loadPage rightPage(), "right", locus, (locus) ->
          showPage rightPage()
          showPage rightNextPage()
          place = getPlace(rightPage())
          if place.onFirstPageOfBook()  # If the right page is the first page of the book, we hide the left
            hidePage leftNextPage()
            hidePage leftPage(), rightPage()
            fn getPlace(rightPage()).getLocus(direction: k.FORWARDS)
          else
            llocus = place.getLocus(direction: k.BACKWARDS)
            loadPage leftPage(), "left", llocus, (llocus) ->
              blankPage leftPage() if isABlankPage leftPage(), "left", llocus
              showPage leftNextPage()
              fn getPlace(rightPage()).getLocus(direction: k.FORWARDS)
        return

      # Special case #6: the left page is the last page of the book
      #   => we hide page on the right
      if getPlace(leftPage()).onLastPageOfBook()
        showPage leftNextPage()
        hidePage rightNextPage()
        hidePage rightPage(), leftPage()
        fn null
        return

      # And, finally, the default case: we just show the next page on right
      showPage leftPage()
      rlocus = getPlace(leftPage()).getLocus(direction: k.FORWARDS)
      loadPage rightPage(), "right", rlocus, (rlocus) ->
        blankPage rightPage() if isABlankPage rightPage(), "right", rlocus
        fn getPlace(rightPage()).getLocus(direction: k.FORWARDS)


  # Lift a page, ie start moving forward or backward in the ebook
  lift = (dir, boxPointX) ->
    return  if p.turnData.lifting or p.turnData.releasing
    p.turnData.points =
      start: boxPointX
      min: boxPointX
      max: boxPointX

    p.turnData.lifting = true
    if dir is k.FORWARDS
      # If we are already at the end of the book, fire an event and don't try to go further
      for page in visiblePages()
        place = getPlace(page)
        if place.onLastPageOfBook()
          p.reader.dispatchEvent "monocle:boundaryend",
            locus: place.getLocus(direction: dir)
            page: page
          resetTurnData()
          return

      onGoingForward boxPointX

    else
      # If we are on the first page of the ebook, fire an event and don't try to move backward
      firstPage = null
      for page in visiblePages()
        # Please note that we have to check that the page if readable because
        # the cover can be forced to be displayed on a right page, and if the
        # user moved backward on a 2-pages spread, we can load a fake page on
        # left that will be blank but with the first page locus.
        if isReadable(page) and getPlace(page).onFirstPageOfBook()
          p.reader.dispatchEvent "monocle:boundarystart",
            locus: getPlace(page).getLocus(direction: dir)
            page: page
          resetTurnData()
          return

      onGoingBackward boxPointX


  # Show an intermediate state where the user is "turning" a page
  turning = (dir, boxPointX) ->
    return  unless p.turnData.points
    return  if p.turnData.lifting or p.turnData.releasing
    checkPoint boxPointX
    page = if dir is k.FORWARDS then rightPage() else leftPage()
    page.style.zIndex = 3
    slideToCursor dir, boxPointX, null, "0"

  # End of a movement: the page is released
  release = (dir, boxPointX) ->
    return  unless p.turnData.points
    if p.turnData.lifting
      p.turnData.releaseArgs = [ dir, boxPointX ]
      return
    return  if p.turnData.releasing
    checkPoint boxPointX
    p.turnData.releasing = true
    if dir is k.FORWARDS
      if p.turnData.points.tap or p.turnData.points.start - boxPointX > (rightPage().offsetWidth / 2) or p.turnData.points.min >= boxPointX
        slideLeft afterGoingForward
      else
        afterCancellingForward()
    else if dir is k.BACKWARDS
      if p.turnData.points.tap or boxPointX - p.turnData.points.start > (leftPage().offsetWidth / 2) or p.turnData.points.max <= boxPointX
        slideRight afterGoingBackward
      else
        afterCancellingBackward()
    else
      console.warn "Invalid direction: " + dir

  # Just a small helper to compute turnData (for the "turn" animation)
  checkPoint = (boxPointX) ->
    p.turnData.points.min = Math.min(p.turnData.points.min, boxPointX)
    p.turnData.points.max = Math.max(p.turnData.points.max, boxPointX)
    p.turnData.points.tap = p.turnData.points.max - p.turnData.points.min < 10


  # Fake the place of one page with the one from the opposite page (useful for blank pages)
  fakePlace = (page, other) ->
    cmpt = other.m.place.properties.component
    page.m.place ||= new Monocle.Place()
    page.m.place.setPlace cmpt, 0

  # Be sure that the content of this page can be read (not blank and not hidden)
  showPage = (page) ->
    page.m.activeFrame.parentNode.parentNode.style.display = "inline-block"
    page.m.activeFrame.style.visibility = "visible"

  # Make this page visible but blank (end of a chapter for example)
  blankPage = (page, other) ->
    page.m.activeFrame.parentNode.parentNode.style.display = "inline-block"
    page.m.activeFrame.style.visibility = "hidden"
    fakePlace page, other if other

  # Hide a page (right page in landscape mode for example)
  hidePage = (page, other) ->
    page.m.activeFrame.parentNode.parentNode.style.display = "none"
    fakePlace page, other if other

  # Return true if the page is displayed on the screen (ie the user can see its border)
  isVisible = (page) ->
    page.m.activeFrame.parentNode.parentNode.style.display != "none"

  # Return true if the content of a page can be read
  isReadable = (page) ->
    return false if page.m.activeFrame.parentNode.parentNode.style.display == "none"
    return false if page.m.activeFrame.style.visibility == "hidden"
    true

  # Does the last page of a component is blank because of a page-spread?
  lastPageIsBlank = (side, place, locus) ->
    return false unless locus.pageSpread
    other = if side == "left" then "right" else "left"
    blank = false
    blank = true if place.oddPageNumber() && locus.pageSpread == side
    blank = true if place.evenPageNumber() && locus.pageSpread == other
    blank = !blank if p.reader.properties.rtl
    blank


  # Start moving forward to the next page(s)
  onGoingForward = (x) ->
    lifted x


  # Start moving backward to the previous page(s)
  onGoingBackward = (x) ->
    page = if isReadable leftPage() then leftPage() else rightPage()
    rlocus = getPlace(page).getLocus(direction: k.BACKWARDS)

    if p.orientation == "portrait"
      loadPage leftNextPage(), "left", rlocus, (locus) ->
        lifted x
      return

    loadPage rightNextPage(), "right", rlocus, (locus) ->
      reversed = if p.orientation == "landscape" then "portrait" else "landscape"
      side = if reader.properties.rtl then "left" else "right"
      place = getPlace(rightNextPage())

      # Special case #1: landscape mode
      if locus.orientation == "landscape"
        enterLandscapeMode()
        loadPage leftNextPage(), "left", locus, (locus) ->
          lifted x
        return
      leaveLandscapeMode() if p.landscapeMode

      # Special case #2: center mode
      # Special case #3: force single page
      if locus.pageSpread == "center" or onSinglePage()
        enterCenterMode()
        loadPage leftNextPage(), "left", locus, (locus) ->
          lifted x
        return
      leaveCenterMode() if p.centerMode

      # Special case #4: no synthetic spread
      if locus.spread == "none" || locus.spread == reversed
        hidePage rightNextPage()
        hidePage rightPage()
        loadPage leftNextPage(), "left", locus, (locus) ->
          lifted x
        return

      # Special case #5: first page of the book
      if place.onFirstPageOfBook()
        hidePage leftPage()
        hidePage leftNextPage(), rightNextPage()
        lifted x
        return

      # Special case #6: page-spread-{left,right}
      if place.onLastPageOfComponent() and lastPageIsBlank("left", place, locus)
        blankPage rightNextPage()
        loadPage leftNextPage(), "left", locus, (locus) ->
          lifted x
        return

      # And finally, the normal case
      llocus = place.getLocus(direction: k.BACKWARDS)
      loadPage leftNextPage(), "left", llocus, (locus) ->
        blankPage leftNextPage() if isABlankPage leftNextPage(), "left", locus
        lifted x


  # Finish the forward move
  afterGoingForward = ->
    fn = (locus) ->
      prepareNextPages locus, announceTurn

    jumpIn leftNextPage(), ->
      flipPages()
      locus = getPlace(leftPage()).getLocus()
      reversed = if p.orientation == "landscape" then "portrait" else "landscape"
      side = if reader.properties.rtl then "left" else "right"

      # Special case #1: landscape mode
      if locus.orientation == "landscape"
        showPage leftPage()
        showPage leftNextPage()
        enterLandscapeMode()
        fn getPlace(leftPage()).getLocus(direction: k.FORWARDS)
        return
      leaveLandscapeMode() if p.landscapeMode

      # Special case #2: center mode
      # Special case #3: single page
      if locus.pageSpread == "center" or onSinglePage()
        showPage leftPage()
        showPage leftNextPage()
        enterCenterMode()
        fn getPlace(leftPage()).getLocus(direction: k.FORWARDS)
        return
      leaveCenterMode() if p.centerMode

      # Special case #4: no synthetic spread
      if locus.spread == "none" || locus.spread == reversed
        showPage leftPage()
        showPage leftNextPage()
        fn getPlace(leftPage()).getLocus(direction: k.FORWARDS)
        return

      # Special case #5: page-spread-right (left if rtl)
      if locus.pageSpread == side and locus.page == 1
        blankPage leftPage()
      else
        showPage leftPage()
        showPage leftNextPage()

        # Special case #6: last page of the book
        if getPlace(leftPage()).onLastPageOfBook()
          hidePage rightNextPage()
          hidePage rightPage()
          fn null
          return

      # Set the visibility of the right page
      rlocus = getPlace(rightPage()).getLocus()
      if isABlankPage rightPage(), "right", rlocus
        blankPage rightPage()
        nlocus = getPlace(leftPage()).getLocus(direction: k.FORWARDS)
      else
        showPage rightPage()
        nlocus = getPlace(rightPage()).getLocus(direction: k.FORWARDS)

      jumpIn rightPage(), ->
        jumpOut rightNextPage()
        fn nlocus


  # Finish the backward move
  afterGoingBackward = ->
    jumpIn rightNextPage() if isVisible rightNextPage()
    if isVisible(leftPage()) and isVisible(leftNextPage())
      jumpIn leftNextPage(), ->
        jumpOut leftPage()
        flipPages()
        announceTurn()
    else
      flipPages()
      announceTurn()

  # Cancel a forward move
  afterCancellingForward = ->
    if isVisible rightPage()
      jumpIn rightPage(), resetTurnData
    else
      resetTurnData()

  # Cancel a backward move
  afterCancellingBackward = ->
    if isVisible leftPage()
      jumpIn leftPage(), resetTurnData
    else
      resetTurnData()


  # After a movement, we prepare the next two pages in background
  # So, the next forward move will be fast
  prepareNextPages = (llocus, callback) ->
    leftPage().style.zIndex = 2
    rightPage().style.zIndex = 2
    leftNextPage().style.zIndex = 1
    rightNextPage().style.zIndex = 1

    unless llocus
      Monocle.defer(callback)
      return

    loadPage leftNextPage(), "left", llocus, (locus) ->
      hidePage leftNextPage() if locus.layout == "pre-paginated" or not isVisible leftPage()

      # Special case #1: landscape mode
      if locus.orientation == "landscape"
        Monocle.defer callback
        return

      # Special case #2: center mode
      if locus.pageSpread == "center"
        Monocle.defer callback
        return

      # Special case #3: single page
      if onSinglePage()
        Monocle.defer callback
        return

      # Special case #4: no synthetic spread
      reversed = if p.orientation == "landscape" then "portrait" else "landscape"
      if locus.spread == "none" || locus.spread == reversed
        Monocle.defer callback
        return

      # Special case #5: page-spread-right (left if rtl)
      #   => we load the same page on the right and we hide the left
      side = if reader.properties.rtl then "left" else "right"
      if locus.pageSpread == side and locus.page == 1
        loadPage rightNextPage(), "right", locus, ->
          blankPage leftNextPage() if isVisible leftPage()
          Monocle.defer callback
        return

      # Special case #6: the left page is the last page of the book
      if getPlace(leftNextPage()).onLastPageOfBook()
        Monocle.defer callback
        return

      # And, finally, the default case: we just show the next page on right
      rlocus = getPlace(leftNextPage()).getLocus(direction: k.FORWARDS)
      loadPage rightNextPage(), "right", rlocus, (rlocus) ->
        if rlocus.layout == "pre-paginated"
          hidePage rightNextPage()
        else if isVisible rightPage()
          blankPage rightNextPage() if locus.pageSpread == side and locus.page == 1
        else
          hidePage rightNextPage()
        Monocle.defer callback


  # A temporary state where a part of a page is "lifted"
  # and so we can show the next page under it.
  lifted = (x) ->
    p.turnData.lifting = false
    releaseArgs = p.turnData.releaseArgs
    if releaseArgs
      p.turnData.releaseArgs = null
      release releaseArgs[0], releaseArgs[1]
    else slideToCursor x  if x

  # Fire the event "end of the turn movement"
  announceTurn = ->
    p.reader.dispatchEvent "monocle:turn"
    resetTurnData()

  # Clean data after a "turn" movement
  resetTurnData = ->
    hideWaitControl()
    p.turnData = {}


  # Make an animation on the x coordinate of an element
  # It's used for horizontal sliding of pages
  setX = (elem, x, options, callback) ->
    # Hack for prepaginated sections
    for prop in ["WebkitTransform", "MozTransform", "transform"]
      if elem.style[prop] and elem.style[prop].match(/scale/)
        Monocle.defer callback if typeof callback is "function"
        return

    duration = undefined
    transition = undefined
    unless options.duration
      duration = 0
    else
      duration = parseInt(options.duration)
    if Monocle.Browser.env.supportsTransition
      Monocle.Styles.transitionFor elem, "transform", duration, options.timing, options.delay
      if Monocle.Browser.env.supportsTransform3d
        Monocle.Styles.affix elem, "transform", "translate3d(" + x + "px,0,0)"
      else
        Monocle.Styles.affix elem, "transform", "translateX(" + x + "px)"
      if typeof callback is "function"
        if duration and Monocle.Styles.getX(elem) isnt x
          Monocle.Events.afterTransition elem, callback
        else
          Monocle.defer callback
    else
      elem.currX = elem.currX or 0
      completeTransition = ->
        elem.currX = x
        Monocle.Styles.setX elem, x
        callback()  if typeof callback is "function"

      unless duration
        completeTransition()
      else
        stamp = (new Date()).getTime()
        frameRate = 40
        step = (x - elem.currX) * (frameRate / duration)
        stepFn = ->
          destX = elem.currX + step
          timeElapsed = ((new Date()).getTime() - stamp) >= duration
          pastDest = (destX > x and elem.currX < x) or (destX < x and elem.currX > x)
          if timeElapsed or pastDest
            completeTransition()
          else
            Monocle.Styles.setX elem, destX
            elem.currX = destX
            setTimeout stepFn, frameRate

        stepFn()

  # Make a page appear
  jumpIn = (pageDiv, callback) ->
    opts = duration: (if Monocle.Browser.env.stickySlideOut then 1 else 0)
    setX pageDiv, 0, opts, callback

  # Make a page disappear
  jumpOut = (pageDiv, callback) ->
    opts = duration: 0
    setX pageDiv, 0, opts , callback

  # Slide the right page to the left
  slideLeft = (callback) ->
    if onSinglePage()
      x = 0 - leftPage().offsetWidth
      setX leftPage(), x, slideOpts(), ->
        leftPage().style.zIndex = 0
        setX leftPage(), 0, {}, callback
    else if isVisible rightPage()
      rightPage().style.zIndex = 3
      x = 0 - rightPage().offsetWidth
      x = -x if p.reader.properties.rtl
      setX rightPage(), x, slideOpts(), ->
        rightPage().style.zIndex = 2
        callback()
    else
      callback()

  # Slide the left page to the right
  slideRight = (callback) ->
    if isVisible leftPage()
      leftPage().style.zIndex = 3
      x = leftPage().offsetWidth
      x = -x if p.reader.properties.rtl
      setX leftPage(), x, slideOpts(), ->
        leftPage().style.zIndex = 2
        callback()
    else
      callback()

  # Slide partially a page to show under it the previous/next page
  slideToCursor = (dir, cursorX, callback, duration) ->
    opts = duration: duration or k.FOLLOW_DURATION
    if dir is k.FORWARDS
      unless isVisible rightPage()
        Monocle.defer callback
        return
      page = rightPage()
      x = Math.min(0, cursorX - (page.offsetWidth * 2))
    else
      unless isVisible leftPage()
        Monocle.defer callback
        return
      page = leftPage()
      x = Math.max(0, cursorX)
    setX page,  x, opts, callback

  # Options for the sliding animations of pages
  slideOpts = ->
    opts =
      timing: "ease-in"
      duration: 320
    now = (new Date()).getTime()
    opts.duration *= 0.5  if p.lastSlide and now - p.lastSlide < 1500
    p.lastSlide = now
    opts


  # Prepare the <div> in the top left corner of pages for the loader control
  ensureWaitControl = ->
    return  if p.waitControl
    p.waitControl = createControlElements: (holder) ->
      holder.dom.make "div", "flippers_slider_wait"
    p.reader.addControl p.waitControl, "page"

  # Show the loading spinner
  showWaitControl = ->
    ensureWaitControl()
    for i in [0...p.pageCount]
      p.reader.dom.find("flippers_slider_wait", i).style.opacity = 1

  # hide the loading spinner
  hideWaitControl = ->
    ensureWaitControl()
    for i in [0...p.pageCount]
      p.reader.dom.find("flippers_slider_wait", i).style.opacity = 0


  # Display only one page in landscape
  enterLandscapeMode = ->
    hidePage rightNextPage()
    hidePage rightPage()
    leftPage().classList.add("landscape")
    leftNextPage().classList.add("landscape")
    p.landscapeMode = true

  # Stop forcing the display of one page in landscape
  leaveLandscapeMode = ->
    leftNextPage().classList.remove("landscape")
    leftPage().classList.remove("landscape")
    p.landscapeMode = false

  # Display only one page in the center of the screen
  enterCenterMode = ->
    hidePage rightNextPage()
    hidePage rightPage()
    leftNextPage().classList.add("center")
    leftPage().classList.add("center")
    p.centerMode = true

  # Stop forcing the display of one page in the center
  leaveCenterMode = ->
    leftNextPage().classList.remove("center")
    leftPage().classList.remove("center")
    p.centerMode = false

  # Add a CSS class, so that the unique page can take all the width of the reader
  enterPortrait = ->
    hidePage rightNextPage()
    hidePage rightPage()
    leftNextPage().classList.add("portrait")
    leftPage().classList.add("portrait")

  # Remove the CSS class for portrait
  leavePortrait = ->
    leftNextPage().classList.remove("portrait")
    leftPage().classList.remove("portrait")

  # Are we on a single page for all the book (not just temporary for a component)?
  onSinglePage = ->
    return true if p.forceSinglePage
    return true if p.orientation == "portrait"
    false

  # Switch the forceSinglePage flag and force a redraw to apply it
  toggleForceSinglePage = ->
    p.forceSinglePage = !p.forceSinglePage
    redraw()


  # Monocle has its way to declare classes and expose an API
  # See https://github.com/joseph/Monocle/wiki/Javascript-object-style
  return new App.Flippers.DoublePages(reader)  if Monocle.Flippers is this
  API = constructor: App.Flippers.DoublePages
  k = API.constants = API.constructor
  p = API.properties =
    # Use up to 4 iframes for pages
    pageCount: 4
    # 0 will use leftIndex and rightIndex for leftPage and rightPage (visibles ones)
    # 1 will use leftNextIndex and rightNextIndex for leftPage and rightPage (visibles ones)
    activeIndex: 0
    leftIndex: 0
    rightIndex: 1
    leftNextIndex: 2
    rightNextIndex: 3
    turnData: {}
    # By default, the book is displayed on one or two pages according to the dimensions and fixed layout rules
    # But the user can force on single page if he prefers
    forceSinglePage: false
    landscapeMode: false
    centerMode: false

  API.pageCount = p.pageCount
  API.addPage = addPage
  API.getPlace = getPlace
  API.moveTo = moveTo
  API.listenForInteraction = listenForInteraction
  API.visiblePages = visiblePages
  API.interactiveMode = interactiveMode
  API.redraw = redraw
  API.toggleForceSinglePage = toggleForceSinglePage
  API.onSinglePage = onSinglePage
  initialize()
  API

# Some constants
App.Flippers.DoublePages.DEFAULT_PANELS_CLASS = Monocle.Panels.TwoPane
App.Flippers.DoublePages.FORWARDS = 1
App.Flippers.DoublePages.BACKWARDS = -1
App.Flippers.DoublePages.FOLLOW_DURATION = 100
Monocle.pieceLoaded "flippers/double_pages"
