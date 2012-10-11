require 'sinatra'
root = File.dirname(__FILE__)
require File.join(root, 'lib/tea_api')
run TeaApi.new
