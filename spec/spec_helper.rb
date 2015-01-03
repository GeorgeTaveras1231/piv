require 'bundler/setup'
Bundler.require :default, :test

require "codeclimate-test-reporter"
require 'webmock/rspec'

TEST_ROOT = __dir__

Dir.glob(File.join(TEST_ROOT, 'support', '**', '*.rb')) do |file|
  require file
end

def connection
  @connection ||= Faraday.new(api_url) do |conn|
    conn.request :json
    conn.response :json
    conn.adapter Faraday.default_adapter
  end
end

def global_dir
  @global_dir ||= File.join(TEST_ROOT, 'fixtures', "piv_test#{SecureRandom.hex(20)}")
end

def api_url
  "https://www.pivotaltracker.com/services/v5/"
end


RSpec.configure do |c|
  c.after(:all) do
    WebMock.allow_net_connect!
  end

  c.before(:all) do
    Piv::Application.global_dir = global_dir
    Piv::Application.connection = connection
  end

  c.before(:each) do
    Piv::Application.for(nil).assure_globally_installed
  end

  c.after(:each) do
    if Dir.exist? global_dir
      FileUtils.rm_rf global_dir
    end
  end
end

CodeClimate::TestReporter.start if ENV['CODECLIMATE_REPO_TOKEN']
