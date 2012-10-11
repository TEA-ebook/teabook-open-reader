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



class App.Views.SettingsPanel extends Backbone.View
  className: 'modal settingsPanel'

  events:
    'change .font':         'changeFont'
    'change .book_style':   'toggleBookStyle'
    'change .single_page':  'forceSinglePage'

  initialize: (options)->
    @reader = options.reader
    App.FontSizeFactor = 0 unless App.FontSizeFactor
    App.Font = "" unless App.Font
    @fontSizeSheet = null
    @fontSheet = null
    @reader.listen 'monocle:destroy', =>
      @resetFontSize()
      @resetFont()
    @changeFont()
    @applyBookStyle()

  render: ->
    @$el.html SMT['ebook/settings_panel']
    @$el.attr('id', "settings")
    # Strange bug on dragDealer when using show/hide :/
    @$el.css
      visibility: 'hidden'
    @$('.book_style').attr 'checked', @bookStyle()
    @$('.font').val App.Font
    _.defer =>
      new Dragdealer 'fontSizeSlider',
        callback: @changeFontSize
        x: App.FontSizeFactor
      @changeFontSize App.FontSizeFactor, 0 if App.FontSizeFactor != 0
    @

  forceSinglePage: (e)=>
    e.preventDefault()
    @reader.properties.flipper.toggleForceSinglePage()

  bookStyle: ->
    $.cookie('bookStyle') == 'true'

  toggleBookStyle: (e)->
    $.cookie('bookStyle', !@bookStyle())
    @applyBookStyle()

  applyBookStyle: ->
    if @bookStyle()
      @reader.dom.addClass 'book'
    else
      @reader.dom.removeClass 'book'

  changeFontSize: (x, y)=>
    App.FontSizeFactor = x

    if @fontSizeSheet
      @reader.removePageStyles @fontSizeSheet
      @fontSizeSheet = null

    if App.FontSizeFactor != 0
      style = RESET_SIZE_STYLESHEET
      style += "html body { font-size: #{(App.FontSizeFactor + 1) * 100}% !important; }"
      @fontSizeSheet = @reader.addPageStyles(style)

  resetFontSize: ->
    if @fontSizeSheet
      @reader.removePageStyles @fontSizeSheet
      @fontSizeSheet = null

  changeFont: (e)->
    App.Font = @$('.font').val() if e

    if @fontSheet
      @reader.removePageStyles @fontSheet
      @fontSheet = null

    if App.Font != ""
      style = "html body p { font-family: \"#{App.Font}\" !important; }"
      @fontSheet = @reader.addPageStyles(style)

  resetFont: ->
    if @fontSheet
      @reader.removePageStyles @fontSheet
      @fontSheet = null

  RESET_SIZE_STYLESHEET = "
  html, body, div, span, p, blockquote, pre, abbr, address, cite, code, del,
  dfn, em, img, ins, kbd, q, samp, small, strong, sub, sup, var, b, i, dl,
  dt, dd, ol, ul, li, fieldset, form, label, legend, table, caption, tbody,
  tfoot, thead, tr, th, td, article, aside, details, figcaption, figure,
  footer, header, hgroup, menu, nav, section, summary, time, mark  {
    font-size: 100% !important;
  }
  h1 {
    font-size: 2em !important
  }
  h2 {
    font-size: 1.8em !important
  }
  h3 {
    font-size: 1.6em !important
  }
  h4 {
    font-size: 1.4em !important
  }
  h5 {
    font-size: 1.2em !important
  }
  h6 {
    font-size: 1.0em !important
  }"
