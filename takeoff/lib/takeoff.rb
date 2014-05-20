require 'logger'
require 'yaml'

require "takeoff/version"
require "takeoff/worker_bee"

begin
  require 'aws-sdk-core'
rescue LoadError
  puts 'Failed to load AWS-SDK-CORE gem'
  puts '  try running: gem install aws-sdk-core'
  exit
end

module Takeoff

  # nothing at the moment
end
