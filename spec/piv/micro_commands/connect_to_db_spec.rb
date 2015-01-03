require 'spec_helper'

describe Piv::MicroCommands::ConnectToDB do
  before do
    FileUtils.mkdir_p migrations_path unless Dir.exist? migrations_path

    migrations = {'first_test_migration' => <<-FirstMigration, 'second_test_migration' => <<-SecondMigration}
      class FirstTestMigration < ActiveRecord::Migration
        def change
          create_table :first
        end
      end
    FirstMigration
      class SecondTestMigration < ActiveRecord::Migration
        def change
          create_table :second
        end
      end
    SecondMigration

    migrations.each.with_index(1) do |(name, migration), index|
      migration_path = File.join(migrations_path, "#{index}_#{name}.rb")
      File.open(migration_path, 'w') do |file|
        file.puts migration.strip_heredoc
      end
    end

    ActiveRecord::Migrator.migrations_path = migrations_path
  end

  let(:command) { described_class.new(config) }
  let(:dir) { File.join(fixture_path, 'micro_commands', 'connect_to_db') }

  let(:db_path) { File.join(dir, 'testdb.sqlite3') }
  let(:migrations_path) { File.join(dir, 'migrate') }

  let(:config) do
    {:adapter => :sqlite3, :database => db_path }
  end

  after do
    if Dir.exist?(dir)
      FileUtils.rm_r dir
    end
  end

  describe '#up' do
    it 'creates db' do
      command.up
      expect(File.exist? db_path).to be true
    end

    it "runs all migrations on the db" do
      command.up
      expect(ActiveRecord::Migrator.last_version).to eq 2
    end
  end

  describe '#down' do
    it 'rolls the db back' do
      command.up
      command.down
      expect(ActiveRecord::Migrator.current_version).to eq 0
    end
  end

end
