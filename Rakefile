require "bundler/gem_tasks"
require "bundler/setup"
require 'sinatra/activerecord/rake'
Bundler.require(:default, :development)

desc 'uninstall fixture project'
task :uninstall do
  FileUtils.rm_r File.join(__dir__, 'test', '.piv')
end
