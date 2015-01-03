require 'spec_helper'

describe Piv::MicroCommands::Mkdir do
  let(:command) { described_class.new(dir) }
  let(:dir) { File.join(__dir__, '..', 'fixtures', 'micro_commands', 'mkdir') }
  after do
    if Dir.exist?(dir) || File.exist?(dir)
      FileUtils.rm_r dir
    end
  end

  describe '#up' do
    it "attempts to create directory" do
      command.up
      expect(Dir.exist? dir).to be true
    end

    context 'when file exist in path given' do
      before do
        FileUtils.touch(dir)
      end

      it 'raises a FailedCommand exception' do
        expect { command.up }.to raise_error Piv::MicroCommands::FailedCommandError
      end
    end
  end

  describe '#done?' do
    it 'returns true if dir already exist' do
      FileUtils.mkdir_p dir
      expect(command).to be_done
    end
  end
end
