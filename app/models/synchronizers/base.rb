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

module Synchronizers
  class Base

    def initialize(user, opts = {})
      @adapter = opts.fetch(:adapter, [:typhoeus])
      @session = opts[:session]
      @config = opts.fetch(:config) { Gaston.synchronizers }
      @user = user
    end

    attr_reader :config, :session

    def synchronize!(record)
      fetching_remote(record) do |remote|
        if remote.nil?
          create_remote!(record)
        else
          if destroyed_local?(record)
            delete_remote!(record)
          else
            if stale_remote?(record, remote)
              update_remote!(record)
            elsif stale_local?(record, remote)
              update_local!(record, remote)
            end
          end
        end
      end

    rescue => error
      msg = "#{self.class} encountered an error: #{error}"
      warn msg
      Rails.logger.error msg
    ensure
      yield if block_given?
    end

    protected

    def update_remote!(record)
      update(record)
    end

    def delete_remote!(record)
      delete(record)
    end

    def create_remote!(record)
      create(record)
    end

    def update_local!(record, remote)
      before_local_update(record, remote)
      record.update_attributes(remote)
      after_local_update(record, remote)
    end

    def stale_remote?(record, remote)
      if remote.respond_to?(:updated_at)
        remote.updated_at < record.updated_at
      else
        true
      end
    end

    def stale_local?(record, remote)
      remote.updated_at > record.updated_at
    end

    def destroyed_local?(record)
      record.destroyed?
    end

    private

    def fetching_remote(record)
      response = read(record)
      if response.success?
        yield response.body
      elsif response.status == 404
        yield nil
      elsif response.status == 403
        Rails.logger.error "#{self.class} error when authenticating"
      else
        msg = "Something unexpected happened when fetching #{response}"
        Rails.logger.error msg
        raise msg
      end
    end

    def read(book)
      run :get, read_url(book)
    end

    def update(book)
      run :put, read_url(book), book
    end

    def create(book)
      run :put, read_url(book), book
    end

    def delete(book)
      run :delete, read_url(book)
    end

    def before_local_update(record, remote)
    end

    def after_local_update(record, remote)
    end

    def run(method, url, body = nil)
      connection.send(method) do |req|
        req.url url
        req.headers['Set-Cookie'] = session
        req.body = body if body
        req.options[:timeout] = timeout_options[:timeout]
        req.options[:open_timeout] = timeout_options[:open_timeout]
      end
    end

    def connection
      return @connection if @connection

      @connection = Faraday::Connection.new do |builder|
                      builder.request :json
                      builder.response :json, :content_type => /\bjson$/
                      builder.response :mashify
                      builder.use :instrumentation
                      builder.adapter *@adapter
                    end
      @connection.basic_auth(*authorization_options) unless authorization_options.empty?
      @connection
    end

    def authorization_options
      return @authorization_options if @authorization_options

      @authorization_options = config['auth'] ? [config['auth']['username'], config['auth']['password']] : []
    end

    def paths
      @paths ||= config['paths'][config_key]
    end

    def host
      @host ||= config['host']
    end

    def read_url(book)
      url_maker(:get, book)
    end

    def update_url(book)
      url_maker(:put, book)
    end

    def create_url(book)
      url_maker(:post, book)
    end

    def delete_url(book)
      url_maker(:delete, book)
    end

    def url_maker(method, book = nil)
      url = join_url_segments(host, paths[method.to_s]).gsub(':user_id', @user.id.to_s)
      url.gsub!(':book_id', book.id.to_s) if book
      url
    end

    def config_key
      self.class.to_s.demodulize.underscore
    end

    def timeout_options
      {timeout: 3, open_timeout: 1}
    end

    def join_url_segments(host, path)
      URI.join(host, path.gsub(%r{^/}, '')).to_s
    end

  end
end
