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

def fixture_path
  @fixture_path ||= File.join(TEST_ROOT, 'fixtures', SecureRandom.hex(10))
end

def global_dir
  @global_dir ||= File.join(fixture_path, 'piv_test')
end

def api_url
  "https://www.pivotaltracker.com/services/v5/"
end

def installer
  @installer ||= Piv::MicroCommands::InstallGlobal.new(global_dir)
end

RSpec.configure do |c|

  c.before(:all) do
    FileUtils.mkdir_p fixture_path

    Piv::Application.global_dir = global_dir
    Piv::Application.connection = connection
  end

  c.after(:all) do
    FileUtils.rm_rf fixture_path

    WebMock.allow_net_connect!
  end

end

CodeClimate::TestReporter.start if ENV['CODECLIMATE_REPO_TOKEN']
