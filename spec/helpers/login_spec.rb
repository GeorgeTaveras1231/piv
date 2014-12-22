describe Piv::Helpers::Login do
  let(:application) do
    Object.new
  end

  before do
    application.extend(described_class)
  end

  let(:istream) { double(:istream, :gets => input) }
  let(:ostream) { double(:ostream, :print => '') }

  describe '#ask_for_credentials' do
    let(:input) { '' }
    before do
      allow(istream).to receive(:gets).and_return('user', 'pass')
      allow(istream).to receive(:noecho) { '' }
    end

    it 'asks for username and password' do
      expect(ostream).to receive(:print).with('User: ')
      expect(ostream).to receive(:print).with('Password: ')
      expect(istream).to receive(:gets)
      application.ask_for_credentials(istream, ostream)
    end
  end

  describe '#user_wants_to_preserve_session?' do
    before do
      allow(application).to receive(:current_session) { current_session }
    end

    let(:current_session) { double(:current_session, :name => 'George') }
    let(:input) { 'y' }

    it 'confirms that the user wants to overide the current session' do
      expect(ostream).to receive(:print).with(a_string_matching(/George has already established a session, do you want to start a new session\?/))
      application.user_wants_to_preserve_session?(istream, ostream)
    end

    context "and user chooses 'y'" do
      let(:input) { 'y' }
      it 'returns false' do
        expect(application.user_wants_to_preserve_session?(istream, ostream)).to be false
      end
    end

    context "and user chooses 'n'" do
      let(:input) { 'n' }

      it 'returns true' do
        expect(application.user_wants_to_preserve_session?(istream, ostream)).to be true
      end
    end
  end
end
