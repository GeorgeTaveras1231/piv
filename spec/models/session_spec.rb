require 'spec_helper'

describe Piv::Session do

  fixture_path = File.join(__dir__, '..', 'fixtures', 'models')
  db_path = File.join(fixture_path, 'test_db')

  before(:all) do
    unless Dir.exist? fixture_path
      FileUtils.mkdir fixture_path
    end
    ActiveRecord::Migrator.migrations_path = 'db/migrate'
    Piv::MicroCommands::ConnectToDB.new(:adapter => :sqlite3, :database => db_path).run(:up)
  end

  after(:all) do
    if Dir.exist? fixture_path
      FileUtils.rm_r fixture_path
    end
  end

  describe 'private#make_only_current' do
    before do
      @other_sessions = %w( 1 2 3 ).map do |token|
        described_class.create(:token => token, :current => true)
      end

      @last_session = described_class.create(:token => '4', :current => true)
    end

    it "makes every other session's current attribute false" do
      expect(@last_session).to be_current
      expect(@other_sessions.none? { |s| s.reload.current? }).to be true
    end
  end
end
