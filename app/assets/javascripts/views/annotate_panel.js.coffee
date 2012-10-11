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



# TODO Create a generic view for pop up, and use inheritance (see SettingsPanel)
class App.Views.Annotate extends Backbone.View
  initialize: ->
    @form = new Backbone.Form(model: @model)

  className: "annotatePanel"

  events:
    'click .close':   'close'
    'submit .annotation_form form': 'saveAnnotation'

  render: ->
    @$el.html SMT['ebook/annotate_panel'] {form: @form.render().el.innerHTML}
    @$el.find('textarea[name=note]')[0].value = @model.get('note') # OMFG. Why? ;_;
    @

  close: (e)->
    e.preventDefault()
    @remove()

  saveAnnotation: (e)->
    e.preventDefault()
    # FIXME: We shouldn't have to do this butt-ugly thing, and use
    # backbone-form's commit(), but so far I haven't quite nailed how to do it
    @model.set('note', @$el.find('textarea[name=note]')[0].value)
    @model.save()
    # TODO: Trigger a visual indicator for pages with annotations
    @options.success() if @options.success
    @remove()
