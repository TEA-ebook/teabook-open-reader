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


unless defined? RAILS_ROOT
  RAILS_ROOT = File.expand_path(File.dirname(__FILE__) + '/../')
  $LOAD_PATH.unshift(RAILS_ROOT) unless $LOAD_PATH.include?(RAILS_ROOT)
end

lib = File.expand_path("#{RAILS_ROOT}/lib/")
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

def stub_module(full_name, &block)
  stub_class_or_module(full_name, Module)
end

def stub_class(full_name, &block)
  stub_class_or_module(full_name, Class)
end

def stub_class_or_module(full_name, kind, &block)
  full_name.to_s.split(/::/).inject(Object) do |context, name|
    begin
      # Give autoloading an opportunity to work
      context.const_get(name)
    rescue NameError
      # Defer substitution of a stub module/class to the last possible
      # moment by overloading const_missing. We use a module here so
      # we can "stack" const_missing definitions for various
      # constants.
      mod = Module.new do
        define_method(:const_missing) do |missing_const_name|
          if missing_const_name.to_s == name.to_s
            value = kind.new
            const_set(name, value)
            value
          else
            super(missing_const_name)
          end
        end
      end
      context.extend(mod)
    end
  end
end

def null_object
  Class.new do
    def method_missing(*_) ; self ; end
  end.new
end
