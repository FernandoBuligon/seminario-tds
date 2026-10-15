require 'sinatra'
require 'json'

set :bind, '127.0.0.1'
set :server, :puma

before do
  content_type :json
end
