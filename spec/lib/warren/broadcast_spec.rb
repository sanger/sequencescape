require 'rails_helper'

RSpec.describe 'Warren::Broadcast' do
  subject(:warren) do
    Warren::Broadcast.new(url: 'example', heartbeat: 30, frame_max: 0, exchange: 'exchange')
  end

  let(:bun_session) { instance_double(Bunny::Session) }
  let(:bun_channel) { instance_double(Bunny::Channel) }
  let(:bun_exchange) { instance_double(Bunny::Exchange) }

  describe '#connect' do
    before do
      expect(Bunny).to receive(:new)
        .with('example', frame_max: 0, heartbeat: 30)
        .and_return(bun_session)
      expect(bun_session).to receive(:start)
    end

    subject { warren.connect }

    it { is_expected.to eq true }
  end

  describe '#with_channel' do
    before do
      expect(Bunny).to receive(:new)
        .with('example', frame_max: 0, heartbeat: 30)
        .and_return(bun_session)
      expect(bun_session).to receive(:start)
      expect(bun_session).to receive(:create_channel).and_return(bun_channel)
    end

    it 'yields a channel' do
      expect { |b| warren.with_chanel(&b) }.to yield_with_args(Warren::Broadcast::Channel)
    end
  end

  describe 'Warren::Broadcast::Channel' do
    let(:channel) { Warren::Broadcast::Channel.new(bun_channel, exchange: 'exchange') }

    describe '#<<' do
      let(:message) { double('message', routing_key: 'key', payload: 'payload') }
      subject { channel << message }

      before do
        expect(bun_channel).to receive(:topic)
          .with('exchange', auto_delete: false, durable: true)
          .and_return(bun_exchange)
        expect(bun_exchange).to receive(:publish)
          .with('payload', routing_key: 'key')
      end

      it { is_expected.to be_a(Warren::Broadcast::Channel) }
    end
  end
end
