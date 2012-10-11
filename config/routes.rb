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



# encoding: utf-8
Tea::Application.routes.draw do

  root to: 'tea_sessions#new'
  match 'manifests/loader', to: 'manifests#loader'
  match 'manifests/reader.appcache', to: 'manifests#reader', format: :text

  devise_for :users
  resources :tea_sessions, only: [:new, :create, :destroy]

  namespace :ebook do
    match 'epub', to: 'epubs#reader', as: :epub_reader, format: :html
    match 'epub_sandbox', to: 'epubs#reader_sandbox', as: :epub_reader_sandbox, format: :html
    resources :epubs do
      resources :components, only: [:show], controller: 'epub/components'
      resources :chapters, only: [:index], controller: 'epub/chapters'
    end
  end

  scope :offline, as: :offline, path: :offline do
    namespace :ebook do
      match 'epub', to: 'epubs#reader', format: :html, offline: true
      match 'epub_sandbox', to: 'epubs#reader_sandbox', format: :html, offline: true
      match 'epubs', to: 'epubs#index', format: :html, offline: true
    end
  end

  resources :books do
    member do
      get :reading_position, to: 'reading_position#show'
      put :reading_position, to: 'reading_position#update'
    end
    resources :bookmarks
    resources :annotations, except: [:new, :edit]
  end

  devise_for :admins
  namespace :admin do
    root to: 'home#index'
    resources :booksellers
  end
  mount Resque::Server.new, at: "/resque", as: :resque

end
