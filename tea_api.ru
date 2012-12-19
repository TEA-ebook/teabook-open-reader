require 'sinatra'
root = File.dirname(__FILE__)
require File.join(root, 'lib/tea_api')
require File.join(root, 'lib/tea_api_config')
run TeaApi.new
