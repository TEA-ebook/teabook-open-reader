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



class App.Misc.TextLocator

  nodeToXpath: (element)->
    return unless element

    xpath = ''
    currentNode = element
    while currentNode && currentNode.tagName != 'HTML'
      if currentNode.nodeType == currentNode.ELEMENT_NODE
        segment = currentNode.tagName.toLowerCase()
        siblings = $(currentNode.parentNode).find("> #{currentNode.tagName}")
        position = siblings.index(currentNode)
        segment += "[#{position + 1}]" if siblings.length > 1
        xpath = "/#{segment}#{xpath}"
      currentNode = currentNode.parentNode
    "/#{xpath}"

  nodeToCSSSelector: (element)->
    return unless element

    cssPath = ''
    currentNode = element
    while currentNode && currentNode.tagName != 'HTML'
      if currentNode.nodeType == currentNode.ELEMENT_NODE
        segment = currentNode.tagName.toLowerCase()
        siblings = $(currentNode.parentNode).find("> #{currentNode.tagName}")
        position = siblings.index(currentNode)
        segment += ":nth-of-type(#{position + 1})" if siblings.length > 1
        if cssPath != ""
          cssPath = "#{segment} > #{cssPath}"
        else
          cssPath = segment
      currentNode = currentNode.parentNode
    cssPath

  firstVisibleElement: (monelem_pages)->
    step = 10
    element = null

    for f in $(monelem_pages).find('iframe')
      offset = 30
      content = f.contentDocument
      body = $(content).find('body')
      bodyHeight = body.height()
      until (element && element.tagName != 'HTML') || (offset > bodyHeight - step)
        # console.log('offset', offset)
        element = content.elementFromPoint(20, offset)
        offset += step
      break if element && element.tagName != 'HTML'

    element unless element.tagName == 'HTML'

  readingPositionPaths: (monelem_pages)=>
    element = @firstVisibleElement(monelem_pages)
    if element
      {xpath: @nodeToXpath(element), selector: @nodeToCSSSelector(element)}
    else
      console.warn('Could not determine reading position !') unless element


