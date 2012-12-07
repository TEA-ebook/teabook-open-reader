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
    hammer = $(p.div).hammer
      prevent_default: true
      swipe: false
      hold: false
    hammer.bind 'tap', proxyEvent tap
    hammer.bind 'transformend', proxyEvent transformend
    hammer.bind 'dragstart', proxyEvent start
    hammer.bind 'drag', proxyEvent move
    hammer.bind 'dragend', proxyEvent end
    p.div

  proxyEvent = (fn) ->
    (e) ->
      evt = makeRelativeEvt e
      #console.warn evt
      fn evt

  makeRelativeEvt = (e) ->
    unless e.position
      if e.touches && e.touches.length == 1
        e.position = e.touches[0]
      else
        console.error "no position"
        console.log e

    if e.position
      if e.position.length
        if e.position.length == 1
          e.position = e.position[0]
        else
          console.error "many positions ?"
          console.log e

    target = e.target || e.srcElement
    while target.nodeType != 1 && target.parentNode
      target = target.parentNode
    if e.touches
      for touch in e.touches
        offset = offsetFor touch, target
        touch.offsetX = offset[0]
        touch.offsetY = offset[1]
    offset = offsetFor e.position, target
    e.position.offsetX = offset[0]
    e.position.offsetY = offset[1]

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

  listenTo = (evtCallbacks) ->
    p.evtCallbacks = evtCallbacks

  deafen = ->
    p.evtCallbacks = {}

  getDirection = (evt) ->
    dir = ""
    x = evt.position.offsetX
    width = p.div.clientWidth
    if x < width / 10
      dir = "backwards"
    else if x > 9 * width / 10
      dir = "forwards"
    dir.toUpperCase()

  start = (evt) ->
    p.direction = getDirection evt
    p.contact = true
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

  swipe = (evt) ->
    alert "swipe #{evt.direction}"
    if evt.direction == "right"
      p.direction = "FORWARDS"
    else if evt.direction == "left"
      p.direction = "BACKWARDS"
    else
      return
    invoke "start", evt
    invoke "end", evt



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
    invoke "gestureend", evt

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
