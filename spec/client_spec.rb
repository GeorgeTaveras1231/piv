require "spec_helper"

describe Piv::Client do

  before do
    allow(Faraday).to receive(:new).with(url) { connection_stub }
  end

  let(:url) { 'http://someplace.com/' + connection_stub.path_prefix }

  let(:connection_stub) do
    double(:connection, :path_prefix => 'prefix',
                        :basic_auth => nil,
                        :get => nil)
  end

  let(:client) { described_class.new(url) }

  describe "#login" do
    it "makes a request to 'me'" do
      expect(connection_stub).to receive(:basic_auth).with('g', 't')
      expect(connection_stub).to receive(:get).with('prefix/me')

      client.login(:user => "g", :password => "t")
    end

    context "when a network error is raised" do
      it "raises a NetworkError" do
        allow(connection_stub).to receive(:get) { raise Faraday::TimeoutError, 'msg' }
        expect { client.login(:user => "g", :password => "t")}.to raise_error Piv::Client::NetworkError
      end

      it "raises a NetworkError" do
        allow(connection_stub).to receive(:get) { raise Faraday::ClientError, 'msg' }
        expect { client.login(:user => "g", :password => "t")}.to raise_error Piv::Client::NetworkError
      end
    end
  end
end
