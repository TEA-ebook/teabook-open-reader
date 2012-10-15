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


module ManifestsHelper

  def reader_file_list
    if Rails.configuration.assets.compress
      application_js = javascript_path('application')
      application_css = stylesheet_path('application')
      reader_js = javascript_path('reader')
      reader_css = stylesheet_path('reader')
      reader_sandbox_js = javascript_path('reader_sandbox')
      reader_sandbox_css = stylesheet_path('reader_sandbox')
    else
      # Ugly but needed when in non-compressed mode :/
      application_js = javascript_include_tag('application').scan(/src="([^ ]*)"/)
      application_css = stylesheet_link_tag('application').scan(/href="([^ ]*)"/)
      reader_js =  javascript_include_tag('reader').scan(/src="([^ ]*)"/)
      reader_css =  stylesheet_link_tag('reader').scan(/href="([^ ]*)"/)
      reader_sandbox_js =  javascript_include_tag('reader_sandbox').scan(/src="([^ ]*)"/)
      reader_sandbox_css =  stylesheet_link_tag('reader_sandbox').scan(/href="([^ ]*)"/)
    end

    files = [
      application_js,
      application_css,
      reader_js,
      reader_css,
      reader_sandbox_js,
      reader_sandbox_css,
      "/offline/ebook/epubs",
      "/offline/ebook/epub",
      "/offline/ebook/epub_sandbox",
      image_path('ajax-loader.gif'),
      asset_path('fontawesome-webfont.ttf'),
      asset_path('museo700.otf')
    ].flatten

    # Add sprites
    Dir.chdir(Rails.root.join 'app/assets/images') do
      files += Dir.glob("**/*-*.png").map{|f| asset_path(f)}
    end

    # Add all covers from user ebooks
    if user_signed_in?
      books = current_user.books
      books = books.bookstore(current_bookseller.bookstore_id) if current_bookseller.present?
      books.each do |e|
        e.cover.versions.each {|_, url| files << url.to_s }
      end
    end

    # Add Bookseller custom stylesheet
    files << stylesheet_path(current_bookseller.stylesheet) if current_bookseller.present?

    files.uniq
  end

end
