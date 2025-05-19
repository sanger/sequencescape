# frozen_string_literal: true

require 'rails_helper'

RAILS_LOG_LEVELS = Logger::Severity.constants.map { |level| level }.map { |level| level.to_s.downcase.to_sym }

RSpec.describe Core::Logging do
  let(:dummy_api_class) do
    Class.new do
      include Core::Logging

      def self.name
        'DummyApiClass'
      end
    end
  end

  let(:logger) { instance_double(Logger) }
  let(:dummy_api_instance) { dummy_api_class.new }

  RAILS_LOG_LEVELS.each do |severity|
    let(:message) { "Test #{severity} message" }

    before do
      allow(Rails).to receive(:logger).and_return(logger)
      allow(logger).to receive(severity)
    end

    context 'when logging messages inside a dummy API class' do
      before { dummy_api_instance.send(severity, message) }

      it "appends #{severity} messages with the API class name" do
        expected_log = "API(DummyApiClass): #{message}"

        expect(Rails.logger).to have_received(severity).with(expected_log)
      end
    end

    context 'when logging messages not in an API class' do
      before { logger.send(severity, message) }

      it "logs #{severity} messages as sent" do
        expected_log = message

        expect(Rails.logger).to have_received(severity).with(expected_log)
      end
    end
  end
end
