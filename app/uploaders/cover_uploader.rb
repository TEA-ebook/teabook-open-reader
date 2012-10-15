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


class CoverUploader < CarrierWave::Uploader::Base

  include CarrierWave::MiniMagick

  storage :file

  def store_dir
    if Rails.env.test?
      "cover_spec/#{model.id.to_s[0..11]}/#{model.id.to_s[12..23]}"
    else
      "cover/#{model.id.to_s[0..11]}/#{model.id.to_s[12..23]}"
    end
  end

  def default_url
    "/fallback/#{mounted_as}/#{[version_name, "default.png"].compact.join('_')}"
  end

  version :library do
    process :resize_and_pad => [101, 151]
  end

  version :detail do
    process :resize_and_pad => [188, 248]
  end

  def extension_white_list
    %w(jpg jpeg png gif)
  end

end
