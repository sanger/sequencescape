# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Postman::Message do
  subject { described_class.new(postman, delivery_info, metadata, payload) }

  let(:postman) do
    instance_double('Postman', main_exchange: main_exchange)
  end
  let(:main_exchange) { instance_double('Postman::Channel', 'main_exchange') }
  let(:delivery_info) { instance_double('Bunny::DeliveryInfo', delivery_tag: 'delivery_tag', routing_key: 'test.key') }
  let(:metadata) { instance_double('Bunny::MessageProperties', headers: headers) }
  let(:headers) { retry_attempts.zero? ? nil : { 'attempts' => retry_attempts } }
  let(:retry_attempts) { 0 }

  describe '#process' do
    context 'a valid payload' do
      let(:sample) { instance_double('Sample') }
      let(:payload) { '["Sample", 1]' }

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

    context 'a invalid string payload' do
      let(:payload) { 'Invalid payload' }

      it 'acknowledges but logs the message' do
        expect(Rails.logger).to receive(:warn).with(/Payload Invalid payload is not JSON.*unexpected token at 'Invalid payload'/)
        expect(main_exchange).to receive(:ack).with('delivery_tag')
        subject.process
      end
    end

    context 'a invalid json payload' do
      let(:sample) { instance_double('Sample') }
      let(:payload) { '{"invalid": "message"}' }

      it 'acknowledges but logs the message' do
        expect(Rails.logger).to receive(:warn).with('Payload {"invalid": "message"} is not an array')
        expect(main_exchange).to receive(:ack).with('delivery_tag')
        subject.process
      end
    end

    context 'a invalid length array' do
      let(:sample) { instance_double('Sample') }
      let(:payload) { '["invalid","array","length"]' }

      it 'acknowledges but logs the message' do
        expect(Rails.logger).to receive(:warn).with('Payload ["invalid","array","length"] is not the correct length')
        expect(main_exchange).to receive(:ack).with('delivery_tag')
        subject.process
      end
    end
  end
end
