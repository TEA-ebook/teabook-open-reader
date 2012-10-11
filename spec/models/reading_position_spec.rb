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

require 'spec_helper'

describe ReadingPosition do

  it "has a valid factory" do
    Fabricate.build(:reading_position).should be_valid
  end

  let(:book) { Fabricate(:ebook_epub) }
  let(:user) { Fabricate(:user) }

  it { should validate_uniqueness_of(:book_id).scoped_to(:user_id) }

  describe ".for_book_and_user" do
    it "creates a new reading position" do
      expect { described_class.for_book_and_user(book, user) }.
        to change { ReadingPosition.count }.by(1)
    end

  end

  describe ".create_or_update_from_api" do

    let(:book) do
      Fabricate(:ebook_epub, api_id: "remote_id", source: "api")
    end
    let(:remote_position) { {epub_cfi: "foobar", updated_at: Time.now.iso8601 } }
    let(:api_data) { {id: "remote_id", reading_position: remote_position} }

    context "when there is no existing record" do
      it "creates a new reading position" do
        expect { described_class.create_or_update_from_api(api_data[:id], user, remote_position) }.
          to change { ReadingPosition.count }.from(0).to(1)
      end
    end

      subject do
        Fabricate(:reading_position, book: book, user: user, epub_cfi: "foo")
      end

    context "when there is an existing record" do
      before { subject }

      let(:api_data) { {id: "remote_id", reading_position: remote_position} }

      it "does not create a new reading position" do
        expect { described_class.create_or_update_from_api(api_data[:id], user, remote_position) }.
          not_to change { ReadingPosition.count }
      end
    end

    context "when the current record is outdated by the external record" do
      let(:remote_position) { {epub_cfi: "foobar", updated_at: (subject.updated_at + 2.minutes).iso8601 } }

      it "updates the current record if it is outdated" do
        subject
        expect { described_class.create_or_update_from_api(api_data[:id], user, remote_position) }.
          to change { ReadingPosition.find(subject.id).epub_cfi }.from("foo").to("foobar")
      end
    end

    context "when the current record is up to date" do
      let(:remote_position) { {epub_cfi: "foobar", updated_at: subject.updated_at } }

      it "is does no update" do
        subject
        expect { described_class.create_or_update_from_api(api_data[:id], user, remote_position) }.
          not_to change { ReadingPosition.find(subject.id).epub_cfi }
      end
    end

  end

end
