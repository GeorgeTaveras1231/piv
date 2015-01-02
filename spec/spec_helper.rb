require 'bundler/setup'
Bundler.require :default, :test

require 'webmock/rspec'

WebMock.disable_net_connect!

Dir.glob(File.join(__dir__, 'support', '**', '*.rb')) do |file|
  require file
end
