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
require File.expand_path('../boot', __FILE__)

# Pick the frameworks you want:
# require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "active_resource/railtie"
require "sprockets/railtie"
# require "rails/test_unit/railtie"

if defined?(Bundler)
  Bundler.require(*Rails.groups(:assets => %w(development test)))
end

module Tea
  class Application < Rails::Application
    config.autoload_paths += %W(#{config.root}/lib/devise)

    config.time_zone = 'Paris'
    config.i18n.default_locale = :fr
    config.encoding = "utf-8"

    config.action_dispatch.x_frame_options = 'SAMEORIGIN'
    config.filter_parameters += [:password, :password_confirmation]

    config.assets.enabled = true
    config.assets.version = '1.0'
    config.assets.js_compressor = :uglifier
    config.assets.precompile += [
      'reader.js',
      'reader.css',
      'reader_sandbox.js',
      'reader_sandbox.css',
      'admin.js',
      'customization_*.css'
    ]

    config.generators do |g|
      g.template_engine :haml
      g.test_framework :rspec
      g.view_specs false
      g.fixture_replacement :fabrication
    end

    # Add font path to compass
    config.assets.paths << "#{Rails.root}/app/assets/fonts"

    config.middleware.use Rack::ContentLength
  end
end
