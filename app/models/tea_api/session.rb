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



class TeaApi::Session
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :email, :password, :bookstore, :session,
    :id, :firstname, :lastname, :birthdate, :country

  validates_presence_of :email, :password, :bookstore

  def initialize(options={})
    options.each do |key, value|
      send("#{key}=", value)
    end if options
  end

  def save
    if self.valid?
      hydra = Typhoeus::Hydra.hydra
      r = TeaApi::Request.build(
        url: Gaston.api.paths.authentication,
        method: :post,
        body: {user: self}.to_json
      )
      hydra.queue(r)
      r.on_complete do |resp|
        case resp.code
        when 200
          h = JSON.parse(resp.body).with_indifferent_access
          h[:user].each do |key, value|
            self.send("#{key}=", value)
          end
          self.session = h[:session]
          return true
        else
          h = JSON.parse(resp.body).with_indifferent_access
          self.errors.add(:base, h[:errors].join(', '))
          return false
        end
      end
      hydra.run
      r.handled_response
    else
      false
    end
  end

  # Representation of TeaApi::Session in user accounts hash
  #
  def to_user_account
    {
      id: id,
      email: email,
      firstname: firstname,
      lastname: lastname,
      birthdate: birthdate,
      country: country
    }.with_indifferent_access
  end

  # For simple_form compatibility
  def new_record!
    true
  end

  # For simple_form compatibility
  def persisted?
    false
  end

end
