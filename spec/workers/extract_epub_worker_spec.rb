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


require 'spec_helper'

describe ExtractEpubWorker do
  let(:ebook) { mock(Ebook::Epub) }

  it 'should find Ebook, call extract and enqueue EpubToHTMLWorker' do
    Ebook::Epub.should_receive(:find).with(42).and_return(ebook)
    ebook.should_receive(:extract).and_return(true)
    ebook.should_receive(:enqueue_conversion).and_return(true)
    ExtractEpubWorker.perform(42)
  end

end
