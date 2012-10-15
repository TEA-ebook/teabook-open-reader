# encoding: utf-8

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


class AnnotationsController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  # GET /annotations.json
  def index
    respond_with book.annotations
  end

  # GET /annotations/1.json
  def show
    @annotation = annotation
    respond_with @annotation
  end

  # POST /annotations.json
  def create
    @annotation = book.annotations.new(params[:annotation])
    @annotation.user = current_user
    @annotation.save
    respond_with @annotation, location: book_annotation_path(book, @annotation)
  end

  # PUT /annotations/1.json
  def update
    @annotation = annotation
    @annotation.update_attributes(params[:annotation])
    respond_with @annotation
  end

  # DELETE /annotations/1.json
  def destroy
    @annotation = annotation
    @annotation.destroy
    head :no_content
  end

protected

  def book
    current_user.books.find(params[:book_id] || params[:epub_id])
  end

  def annotation
    annotation = book.annotations.find(params[:id])
    annotation.user = current_user
    annotation
  end
end
