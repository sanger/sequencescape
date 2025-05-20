# frozen_string_literal: true

require 'rails_helper'

# See levels list at https://ruby-doc.org/stdlib-2.6.3/libdoc/logger/rdoc/Logger.html
RAILS_LOG_LEVELS = %i[debug info warn error fatal unknown].freeze
API_LOG_LEVELS = %i[debug info error].freeze

RSpec.describe Core::Logging do
  let(:logger) { instance_double(Logger) }
  let(:message) { "This is a test message with severity #{severity}." }

  let(:dummy_api_class) do
    Class.new do
      include Core::Logging

      def self.name
        'DummyApiClass'
      end
    end
  end
  let(:dummy_api_instance) { dummy_api_class.new }

  before do
    allow(Rails).to receive(:logger).and_return(logger)
    allow(logger).to receive(severity)
  end

  context 'when logging to a dummy API instance' do
    API_LOG_LEVELS.each do |api_log_level|
      context "with #{api_log_level} severity" do
        let(:severity) { api_log_level }

        before { dummy_api_instance.send(severity, message) }

        it "appends the API instance name to #{api_log_level} messages" do
          expected_log = "API(DummyApiClass): #{message}"
          expect(Rails.logger).to have_received(severity).with(expected_log)
        end
      end
    end
  end

  context 'when logging to a dummy API class' do
    API_LOG_LEVELS.each do |api_log_level|
      context "with #{api_log_level} severity" do
        let(:severity) { api_log_level }

        before { dummy_api_class.send(severity, message) }

        it "appends the API class name to #{api_log_level} messages" do
          expected_log = "API(DummyApiClass): #{message}"
          expect(Rails.logger).to have_received(severity).with(expected_log)
        end
      end
    end
  end

  context 'when logging not in an API' do
    RAILS_LOG_LEVELS.each do |rails_log_level|
      let(:severity) { rails_log_level }
      context "with #{rails_log_level} severity" do
        before { logger.send(severity, message) }

        it "passes the #{rails_log_level} messages unaltered" do
          expected_log = message
          expect(Rails.logger).to have_received(severity).with(expected_log)
        end
      end
    end
  end
end
