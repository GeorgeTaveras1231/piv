require 'spec_helper'

describe Piv::MicroCommands::InstallGlobal do
  let(:command) { described_class.new(dir) }
  let(:dir) { File.join(__dir__, '..', '..', 'fixtures', 'micro_commands', 'install_global') }

  describe 'private#sub_commands' do
    it 'returns the expected commands' do
      expect(command.send(:sub_commands)).to include(
        an_instance_of(Piv::MicroCommands::Mkdir),
        an_instance_of(Piv::MicroCommands::ConnectToDB))
    end
  end

  after do
    if Dir.exist? dir
      FileUtils.rm_r dir
    end
  end

  describe '#up' do
    before do
      allow(command).to receive(:sub_commands) { [first_sub_command, second_sub_command] }
    end

    let(:first_sub_command) { double(:first_sub_command, :done? => true) }
    let(:second_sub_command) { double(:second_sub_command, :done? => false, :run => nil) }

    it 'runs the subcommands that are not done' do
      expect(second_sub_command).to receive(:run)
      command.up
    end

    it 'skips the subcommands that are done' do
      expect(first_sub_command).not_to receive(:run)
      command.up
    end
  end

  describe '#down' do
    before do
      allow(command).to receive(:done?) { done? }
    end

    context 'when #done? is true' do
      before do
        FileUtils.mkdir_p dir
      end

      let(:done?) { true }
      it 'removes the global_dir' do
        command.down
        expect(Dir.exist? dir).to be false
      end
    end
  end

end
