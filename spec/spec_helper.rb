require 'bundler/setup'
Bundler.require :default, :test

require "codeclimate-test-reporter"
require 'webmock/rspec'


Dir.glob(File.join(__dir__, 'support', '**', '*.rb')) do |file|
  require file
end

RSpec.configure do |c|
  c.after(:all) do
    WebMock.allow_net_connect!
  end
end

CodeClimate::TestReporter.start if ENV['CODECLIMATE_REPO_TOKEN']
