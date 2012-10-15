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



# TODO spec
class Ebook::EpubsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :fetch_book!, only: [:show, :edit, :update, :destroy]
  respond_to :html, :json

  # GET /ebook/epubs
  # GET /ebook/epubs.json
  def index
    respond_to do |format|
      format.json {
        if current_bookseller.present?
          @ebooks = current_user.books.bookstore(current_bookseller.bookstore_id)
        else
          @ebooks = current_user.books
        end
        # FIXME UGLY !
        # TODO specs
        @ebooks.each do |e|
          e.set :purchase, current_user.purchases[e.id.to_s]
          e.set :reading_position, current_user.reading_position(e).as_json(minimal: true)
          e.set :number_of_bookmarks, (current_user.number_of_bookmarks[e.id.to_s]||0)
        end
        respond_with @ebooks.as_json(reading_position: true)
      }
      format.html{ import_user_books }
    end
  end

  # GET /ebook/epubs/1
  # GET /ebook/epubs/1.json
  def show
    respond_with @ebook.as_json(components: true, chapters: true)
  end

  # GET /ebook/epubs/new
  # GET /ebook/epubs/new.json
  def new
    @ebook = Ebook::Epub.new
    respond_with @ebook
  end

  # GET /ebook/epubs/1/edit
  def edit
    respond_with @ebook
  end

  # POST /ebook/epubs
  # POST /ebook/epubs.json
  def create
    @ebook = Ebook::Epub.new((params[:ebook_epub]||{}).merge(source: 'upload', format: 'epub'))
    @ebook.users << current_user

    respond_to do |format|
      if @ebook.save
        # TODO spec
        current_user.create_uploaded_purchase! @ebook
        format.html { redirect_to ebook_epubs_url, notice: 'Ebook::Epub was successfully created.' }
        format.json { render json: @ebook, status: :created, location: @ebook }
      else
        format.html { render action: "new" }
        format.json { render json: @ebook.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /ebook/epubs/1
  # PUT /ebook/epubs/1.json
  def update
    respond_to do |format|
      if @ebook.update_attributes(params[:ebook_epub])
        format.html { redirect_to ebook_epubs_url, notice: 'Ebook::Epub was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @ebook.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /ebook/epubs/1
  # DELETE /ebook/epubs/1.json
  def destroy
    @ebook.destroy

    respond_to do |format|
      format.html { redirect_to ebook_epubs_url }
      format.json { head :no_content }
    end
  end

  # GET /ebook/epub.html
  def reader
    render :reader, layout: false
  end

  # GET /ebook/epub_sandbox.html
  def reader_sandbox
    # TODO we should respond with the content-type "text/html-sandboxed"
    # when the supported browsers will accept it.
    # See http://www.w3.org/TR/2011/WD-html5-20110525/iana.html#text-html-sandboxed
    render :reader_sandbox, layout: false
  end

protected

  def fetch_book!
    @ebook = current_user.books.find(params[:id])
  end

  # Import user books if needed
  #
  def import_user_books
    session[:tea_sessions].each do |bookstore_id, cookie|
      # Sign out user if cookie is expire
      sign_out_and_redirect current_user and return unless bookstore_cookie bookstore_id
      if current_user.should_reimport_books?(bookstore_id)
        current_user.enqueue_import_books bookstore_cookie(bookstore_id), bookstore_id
      end
    end
  end

end
