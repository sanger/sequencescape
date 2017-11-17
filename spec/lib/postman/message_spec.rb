require 'rails_helper'

RSpec.describe Postman::Message do
  let(:postman) do
    instance_double('Postman', main_exchange: main_exchange)
  end
  let(:main_exchange) { instance_double('Postman::Channel', 'main_exchange') }
  let(:delivery_info) { instance_double('Bunny::DeliveryInfo', delivery_tag: 'delivery_tag', routing_key: 'test.key') }
  let(:metadata) { instance_double('Bunny::MessageProperties', headers: headers) }
  let(:headers) { retry_attempts.zero? ? nil : { 'attempts' => retry_attempts } }
  let(:retry_attempts) { 0 }
  let(:payload) { '["Sample", 1]' }
  subject { described_class.new(postman, delivery_info, metadata, payload) }

  describe '#process' do
    let(:sample) { instance_double('Sample') }
    it 'calls broadcast to describe record' do
      expect(Sample).to receive(:find).with(1).and_return(sample)
      expect(sample).to receive(:broadcast)
      allow(main_exchange).to receive(:ack).with('delivery_tag')
      subject.process
    end

    it 'acknowledges the message' do
      allow(Sample).to receive(:find).with(1).and_return(sample)
      allow(sample).to receive(:broadcast)
      expect(main_exchange).to receive(:ack).with('delivery_tag')
      subject.process
    end
  end
end
