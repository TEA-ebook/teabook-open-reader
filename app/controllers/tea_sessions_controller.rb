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



class TeaSessionsController < ApplicationController
  before_filter :redirect_signed_in_users, except: [:destroy]

  # GET /tea_sessions/new
  #
  def new
    @tea_session = TeaApi::Session.new(
      bookstore: current_bookseller.try(:bookstore_id)
    )
  end

  # POST /tea_sessions
  #
  def create
    @tea_session = TeaApi::Session.new(params[:tea_api_session])
    @tea_session.bookstore = Gaston.bookstore
    # If we are in a development env with no internet connexion
    # We automatically sign in the last user of database
    # Can also be useful when the TEA API is down
    if Rails.env.development? && ENV['OFFLINE']
      session[:tea_sessions][@tea_session.bookstore] = {'id' => 'test', 'expire' => (Time.now + 1.month).to_i}
      user = User.find_or_create_from_tea_session(@tea_session)
      user.remember_me = true
      user.enqueue_import_books bookstore_cookie, @tea_session.bookstore
      sign_in_and_redirect user
    elsif @tea_session.save
      session[:tea_sessions][@tea_session.bookstore] = @tea_session.session
      user = User.find_or_create_from_tea_session(@tea_session)
      user.remember_me = true
      user.enqueue_import_books bookstore_cookie(@tea_session.bookstore), @tea_session.bookstore
      sign_in_and_redirect user
    else
      render :new
    end
  end

  # DELETE /tea_sessions/:bookstore
  def destroy
    session[:tea_sessions].delete params[:id]
    # FIXME Don't destroy session if the current account is connected
    # on another bookstore
    sign_out_and_redirect current_user
  end

  private

    def redirect_signed_in_users
      redirect_to ebook_epubs_path if user_signed_in?
    end

end
