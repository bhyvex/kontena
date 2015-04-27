begin
  require 'dotenv'
  Dotenv.load
rescue LoadError
end

ENV['RACK_ENV'] = 'development' unless ENV['RACK_ENV']

require 'celluloid'
require 'sucker_punch'
require 'fist_of_fury'
require 'roda'
require 'mongoid'
require 'json'
require 'mutations'
require 'logger'
require 'msgpack'
require 'tilt/jbuilder.rb'

Dir[__dir__ + '/initializers/*.rb'].each {|file| require file }

Dir[__dir__ + '/helpers/*.rb'].each {|file| require file }

Dir[__dir__ + '/models/*.rb'].each {|file| require file }

Dir[__dir__ + '/mailers/*.rb'].each {|file| require file }

Dir[__dir__ + '/mutations/**/*.rb'].each {|file| require file }

Dir[__dir__ + '/services/**/*.rb'].each {|file| require file }

Dir[__dir__ + '/jobs/**/*.rb'].each {|file| require file }

