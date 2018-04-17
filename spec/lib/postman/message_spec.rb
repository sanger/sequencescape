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

    it 'acknowledges the message if the record is destroyed' do
      allow(Sample).to receive(:find).with(1).and_raise(ActiveRecord::RecordNotFound)
      expect(main_exchange).to receive(:ack).with('delivery_tag')
      subject.process
    end

    it 'deadletters the message if an exception is raised' do
      allow(Sample).to receive(:find).with(1).and_return(sample)
      allow(sample).to receive(:broadcast).and_raise(NameError, "undefined local variable or method `fasdgsf' for main:Object'")
      expect(main_exchange).to receive(:nack).with('delivery_tag')
      subject.process
    end

    it 'requeues the message if a database connection exception is raised' do
      allow(Sample).to receive(:find).with(1).and_raise(ActiveRecord::StatementInvalid,
                                                        'Mysql2::Error: MySQL server has gone away: SELECT  `batches`.* FROM `batches` ORDER BY `batches`.`id` ASC LIMIT 1')
      expect(main_exchange).to receive(:nack).with('delivery_tag', false, true)
      expect(postman).to receive(:pause!)
      subject.process
    end
  end
end
