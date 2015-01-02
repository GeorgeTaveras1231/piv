require 'bundler/setup'
Bundler.require :default, :test

require "codeclimate-test-reporter"
require 'webmock/rspec'


Dir.glob(File.join(__dir__, 'support', '**', '*.rb')) do |file|
  require file
end

WebMock.disable_net_connect!
CodeClimate::TestReporter.start
