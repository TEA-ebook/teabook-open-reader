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



class Admin::BooksellersController < AdminController
  respond_to :html

  # GET /booksellers
  def index
    @booksellers = Bookseller.all
  end

  # GET /booksellers/1
  def show
    @bookseller = Bookseller.find(params[:id])
  end

  # GET /booksellers/new
  def new
    @bookseller = Bookseller.new
  end

  # POST /booksellers
  def create
    @bookseller = Bookseller.new(params[:bookseller])

    if @bookseller.save
      redirect_to [:admin, @bookseller], notice: 'Bookseller was successfully created.'
    else
      render action: "new"
    end
  end

  # GET /booksellers/1/edit
  def edit
    @bookseller = Bookseller.find(params[:id])
  end

  # PUT /booksellers/1
  def update
    @bookseller = Bookseller.find(params[:id])

    if @bookseller.update_attributes(params[:bookseller])
      redirect_to [:admin, @bookseller], notice: 'Bookseller was successfully updated.'
    else
      render action: "edit"
    end
  end

  # DELETE /booksellers/1
  def destroy
    @bookseller = Bookseller.find(params[:id])
    @bookseller.destroy
    redirect_to admin_booksellers_url
  end
end
