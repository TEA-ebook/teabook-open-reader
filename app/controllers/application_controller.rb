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


class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :define_bookseller
  before_filter :define_tea_sessions

  # Useful for the admin layout on devise
  layout :layout_by_resource

  helper_method :bookstore_session, :current_bookseller, :online?

protected

  def online?
    params[:offline].blank?
  end

  # Get the Bookseller from current domain
  def define_bookseller
    @current_bookseller = Bookseller.where(domain: request.host).one
  end

  # Return the current bookseller for this domain (or nil)
  #
  def current_bookseller
    @current_bookseller
  end

  # Define tea_sessions to an empty hash if don't exists
  #
  def define_tea_sessions
    session[:tea_sessions] ||= {}
  end

  # Is a session exists for the current bookstore
  # Is a bookstore is given, check for this one instead of current one
  #
  def bookstore_session(bookstore = nil)
    if bookstore.present?
      r = session[:tea_sessions][bookstore]
    elsif current_bookseller.present?
      r = session[:tea_sessions][current_bookseller.bookstore_id]
    end
    return r['id'] if r.present? && (r['expire'].to_i > Time.now.to_i)
    false
  end
  alias :bookstore_cookie :bookstore_session

  def after_sign_in_path_for(resource)
    if resource.is_a? Admin
      admin_root_path
    else
      ebook_epubs_path
    end
  end

  def after_sign_out_path_for(resource)
    if resource == :admin
      admin_root_path
    else
      root_path
    end
  end

  def layout_by_resource
    if devise_controller? && resource_name == :admin
      "admin"
    else
      "application"
    end
  end
end
