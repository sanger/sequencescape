# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::BaseClient do
  let(:conn) { instance_double(Faraday::Connection) }
  let(:client_class) do
    Class.new(described_class) do
      def self.name
        'HTTPClients::TestHTTPClient'
      end

      public :default_headers, :proxy
    end
  end
  let(:client) { client_class.new(conn) }

  around do |example|
    configatron_dup = configatron.dup
    example.run
    configatron.reset_to(configatron_dup)
  end

  describe '#initialize' do
    it 'sets the connection' do
      expect(client.instance_variable_get(:@conn)).to eq(conn)
    end
  end

  describe '#default_headers' do
    it 'returns a User-Agent header with the client name' do
      expect(client.default_headers['User-Agent']).to eq('Sequencescape Test HTTP Client')
    end
  end

  describe '#proxy' do
    context 'when disable_web_proxy is true' do
      before { configatron.disable_web_proxy = true }

      it 'returns nil' do
        expect(client.proxy).to be_nil
      end
    end

    context 'when configatron.proxy is present' do
      before do
        configatron.disable_web_proxy = false
        configatron.proxy = 'http://proxy.example.com'
      end

      it 'returns configatron.proxy' do
        expect(client.proxy).to eq('http://proxy.example.com')
      end
    end

    context 'when no proxy is set' do
      before do
        configatron.disable_web_proxy = false
        configatron.proxy = nil
      end

      it 'returns nil' do
        expect(client.proxy).to be_nil
      end
    end
  end
end
