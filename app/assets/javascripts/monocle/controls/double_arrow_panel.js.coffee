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



App.Controls.DoubleArrowPanel = () ->
  createControlElements = (cntr) ->
    p.div = cntr.dom.make("div", k.CLS.panel)
    for direction in ['forwards', 'backwards']
      p["arrow_#{direction}"] = p.div.dom.append("div", k.CLS.arrow)
      p["arrow_#{direction}"].dom.addClass direction
      p["arrow_#{direction}"].dom.setStyles k.DEFAULT_STYLES.arrow[direction]
    p.div.dom.setStyles k.DEFAULT_STYLES.panel
    hammer = $(p.div).hammer()
    hammer.bind 'tap', (e) ->
      tap fixEvt e
    hammer.bind 'transformend', (e) ->
      transformend fixEvt e
    hammer.bind 'dragstart', (e) ->
      start fixEvt e
    hammer.bind 'drag', (e) ->
      move fixEvt e
    hammer.bind 'dragend', (e) ->
      end fixEvt e
    #Monocle.Events.listenForContact p.div,
    #  start: start
    #  move: move
    #  end: end
    #  cancel: cancel
    #,
    #  useCapture: false
    #Monocle.Events.listenForTap p.div, tap
    p.div

  listenTo = (evtCallbacks) ->
    p.evtCallbacks = evtCallbacks

  deafen = ->
    p.evtCallbacks = {}

  getDirection = (evt) ->
    dir = ""
    x = evt.touches[0].offsetX
    width = p.div.clientWidth
    if x < width / 10
      dir = "backwards"
    else if x > 9 * width / 10
      dir = "forwards"
    dir.toUpperCase()

  start = (evt) ->
    p.direction = getDirection evt
    p.contact = true
    #evt.m.offsetX += p.div.offsetLeft
    #evt.m.offsetY += p.div.offsetTop
    expand()
    invoke "start", evt

  move = (evt) ->
    return  unless p.contact
    invoke "move", evt

  end = (evt) ->
    return  unless p.contact
    Monocle.Events.deafenForContact p.div, p.listeners
    contract()
    p.contact = false
    invoke "end", evt

  cancel = (evt) ->
    return  unless p.contact
    Monocle.Events.deafenForContact p.div, p.listeners
    contract()
    p.contact = false
    invoke "cancel", evt

  tap = (evt) ->
    p.direction = getDirection evt
    invoke "start", evt
    invoke "end", evt

  fixEvt = (e) ->
    unless e.position
      e.position = p.lastEvt.position

    target = e.target || e.srcElement
    while target.nodeType != 1 && target.parentNode
      target = target.parentNode
    for touch in e.touches
      offset = offsetFor touch, target
      touch.offsetX = offset[0]
      touch.offsetY = offset[1]

    p.lastEvt = e
    e

  offsetFor = (touch, elem) ->
    if elem.getBoundingClientRect
      # Why subtract documentElement position? It's always zero, right?
      # Nope, not on Android when zoomed in.
      dr = document.documentElement.getBoundingClientRect()
      er = elem.getBoundingClientRect()
      r =
        left: er.left - dr.left
        top: er.top - dr.top
    else
      r =
        left: elem.offsetLeft
        top: elem.offsetTop
      while (elem = elem.offsetParent)
        if elem.offsetLeft || elem.offsetTop
          r.left += elem.offsetLeft
          r.top += elem.offsetTop
    [touch.x - r.left, touch.y - r.top]

  invoke = (evtType, evt) ->
    p.evtCallbacks[evtType] API, evt, p.direction  if p.evtCallbacks[evtType]
    evt.preventDefault()

  expand = ->
    return  if p.expanded
    p.div.dom.addClass k.CLS.expanded
    p.expanded = true

  contract = (evt) ->
    return  unless p.expanded
    p.div.dom.removeClass k.CLS.expanded
    p.expanded = false

  gestureStart = (evt) ->

  gestureMove = (evt) ->

  transformend = (evt) ->
    p.direction = ""
    invoke "gestureend",
      m:
        offsetX: evt.scale
        offsetY: 0

  gestureCancel = (evt) ->

  API = constructor: App.Controls.DoubleArrowPanel
  k = API.constants = API.constructor
  p = API.properties = evtCallbacks: {}
  API.createControlElements = createControlElements
  API.listenTo = listenTo
  API.deafen = deafen
  API.expand = expand
  API.contract = contract
  API

App.Controls.DoubleArrowPanel.CLS =
  panel: "panel"
  expanded: "controls_panel_expanded"
  arrow: "arrow"

App.Controls.DoubleArrowPanel.DEFAULT_STYLES =
  panel:
    position: "absolute"
    height: "100%"
    width: "100%"
  arrow:
    forwards:
      position: "absolute"
      height: "80px"
      width: "50px"
      top: "50%"
      left: "100%"
    backwards:
      position: "absolute"
      height: "80px"
      width: "50px"
      top: "50%"
      right: "100%"

Monocle.pieceLoaded "controls/double_arrow_panel"
