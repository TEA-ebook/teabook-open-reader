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


class ReadingPositionController < ApplicationController
  before_filter :authenticate_user!
  respond_to :json

  def show
    respond_with reading_position
  end

  def update
    if reading_position.update_attributes!(params['reading_position'].except(:epub_cfi))
      head :no_content
    else
      render json: reading_position.errors, status: :unprocessable_entity
    end
  end

protected

  def book
    current_user.books.find(params[:id])
  end

  def reading_position
    return @reading_position if @reading_position
    # FIXME: Enable reading position synchronization once everything is setup
    # to effectively communicate with TEA (publications list is OK, etc.)
    # Synchronizers::ReadingPosition.new(current_user, session: bookstore_session).synchronize!(current_user.reading_position(book)) do
      @reading_position ||= current_user.reading_position(book)
    # end
    @reading_position
  end
end
