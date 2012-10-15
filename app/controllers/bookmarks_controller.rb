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


class BookmarksController < ApplicationController
  helper_method :book, :bookmarks

  before_filter :authenticate_user!

  # GET /bookmarks
  # GET /bookmarks.json
  def index
    @bookmarks = book.bookmarks

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @bookmarks }
    end
  end

  # GET /bookmarks/1
  # GET /bookmarks/1.json
  def show
    @bookmark = bookmark

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @bookmark }
    end
  end

  # GET /bookmarks/new
  # GET /bookmarks/new.json
  def new
    @bookmark = book.bookmarks.new

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @bookmark }
    end
  end

  # GET /bookmarks/1/edit
  def edit
    @bookmark = bookmark
  end

  # POST /bookmarks
  # POST /bookmarks.json
  def create
    @bookmark = book.bookmarks.new(params[:bookmark])
    @bookmark.user = current_user

    respond_to do |format|
      if @bookmark.save
        format.html { redirect_to book_bookmark_path(book, bookmark), notice: 'Bookmark was successfully created.' }
        format.json { render json: @bookmark, status: :created, location: @bookmark }
      else
        format.html { render action: "new" }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /bookmarks/1
  # PUT /bookmarks/1.json
  def update
    @bookmark = bookmark

    respond_to do |format|
      if @bookmark.update_attributes(params[:bookmark])
        format.html { redirect_to book_bookmark_path(book, bookmark), notice: 'Bookmark was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @bookmark.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /bookmarks/1
  # DELETE /bookmarks/1.json
  def destroy
    bookmark.destroy

    respond_to do |format|
      format.html { redirect_to book_bookmarks_url(book) }
      format.json { head :no_content }
    end
  end

  def reading_position
    @reading_position = current_user.reading_position(book)

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @reading_position }
    end
  end

protected

  def book
    @book ||= current_user.books.find(params[:book_id] || params[:epub_id])
  end

  def bookmark
    return @bookmark if @bookmark

    @bookmark = book.bookmarks.find(params[:id])
    @bookmark.user = current_user

    @bookmark
  end
end
