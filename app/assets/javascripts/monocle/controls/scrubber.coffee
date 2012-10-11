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



App.Controls.Scrubber = (reader) ->
  initialize = ->
    p.reader = reader
    p.reader.listen "monocle:loaded", updateNeedles
    p.reader.listen "monocle:turn", updateNeedles
    updateNeedles()

  pixelToPlace = (x, cntr) ->
    unless p.componentIds
      p.componentIds = p.reader.getBook().properties.componentIds
      p.componentWidth = 100 / p.componentIds.length
    pc = (x / cntr.offsetWidth) * 100
    cmpt = p.componentIds[Math.floor(pc / p.componentWidth)]
    cmptPc = ((pc % p.componentWidth) / p.componentWidth)
    componentId: cmpt
    percentageThrough: cmptPc

  placeToPixel = (place, cntr) ->
    unless p.componentIds
      p.componentIds = p.reader.getBook().properties.componentIds
      p.componentWidth = 100 / p.componentIds.length
    componentIndex = p.componentIds.indexOf(place.componentId())
    pc  = p.componentWidth * componentIndex
    pc += place.percentageThrough() * p.componentWidth
    Math.round (pc / 100) * cntr.offsetWidth

  updateNeedles = ->
    return  if p.hidden or not p.reader.dom.find(k.CLS.container)
    place = p.reader.getPlace()
    cntr = p.reader.dom.find(k.CLS.container)
    x = if place.onFirstPageOfBook()
          0
        else if reader.getPlace(reader.visiblePages().pop()).onLastPageOfBook()
          cntr.offsetWidth
        else
          placeToPixel place, cntr

    i = 0
    while needle = p.reader.dom.find(k.CLS.needle, i)
      setX needle, x - needle.offsetWidth / 2
      p.reader.dom.find(k.CLS.trail, i).style.width = x + "px"
      ++i

  setX = (node, x) ->
    cntr = p.reader.dom.find(k.CLS.container)
    x = Math.min(cntr.offsetWidth - node.offsetWidth, x)
    x = Math.max(x, 0)
    Monocle.Styles.setX node, x

  createControlElements = (holder) ->
    cntr = holder.dom.make("div", k.CLS.container)
    track = cntr.dom.append("div", k.CLS.track)
    needleTrail = cntr.dom.append("div", k.CLS.trail)
    needle = cntr.dom.append("div", k.CLS.needle)
    bubble = cntr.dom.append("div", k.CLS.bubble)
    cntrListeners = null
    bodyListeners = null

    moveEvt = (evt, x) ->
      evt.preventDefault()
      x = (if (typeof x is "number") then x else evt.m.registrantX)
      place = pixelToPlace(x, cntr)
      setX needle, x - needle.offsetWidth / 2
      book = p.reader.getBook()
      chps = book.chaptersForComponent(place.componentId)
      cmptIndex = p.componentIds.indexOf(place.componentId)
      chp = chps[Math.floor(chps.length * place.percentageThrough)]
      percentage = ((x / $(track).width()) * 100).toFixed()
      if cmptIndex > -1 and book.properties.components[cmptIndex]
        actualPlace = Monocle.Place.FromPercentageThrough(book.properties.components[cmptIndex], place.percentageThrough)
        percentage = (actualPlace.percentageOfBook() * 100).toFixed()
        chp = actualPlace.chapterInfo() or chp
      legend = percentage + " % "  if percentage
      legend += chp.title  if chp
      bubble.innerHTML = legend
      setX bubble, x - bubble.offsetWidth / 2
      p.lastX = x
      place

    endEvt = (evt) ->
      place = moveEvt(evt, p.lastX)
      p.reader.moveTo
        percent: place.percentageThrough
        componentId: place.componentId

      Monocle.Events.deafenForContact cntr, cntrListeners
      Monocle.Events.deafenForContact document.body, bodyListeners
      cntrListeners = null
      bodyListeners = null
      bubble.style.display = "none"

    startFn = (evt) ->
      bubble.style.display = "block"
      moveEvt evt
      Monocle.Events.deafenForContact cntr, cntrListeners           if cntrListeners
      Monocle.Events.deafenForContact document.body, bodyListeners  if bodyListeners
      cntrListeners = Monocle.Events.listenForContact(cntr, move: moveEvt)
      bodyListeners = Monocle.Events.listenForContact(document.body, end: endEvt)

    Monocle.Events.listenForContact cntr,
      start: startFn

    cntr

  return new App.Controls.Scrubber(reader)  if Monocle.Controls is this
  API = constructor: Monocle.Controls.Scrubber
  k = API.constants = API.constructor
  p = API.properties = {}
  API.createControlElements = createControlElements
  API.updateNeedles = updateNeedles
  initialize()
  API

Monocle.Controls.Scrubber.CLS =
  container: "controls_scrubber_container"
  track: "controls_scrubber_track"
  needle: "controls_scrubber_needle"
  trail: "controls_scrubber_trail"
  bubble: "controls_scrubber_bubble"

Monocle.pieceLoaded "controls/scrubber"
