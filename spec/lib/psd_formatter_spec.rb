# frozen_string_literal: true

require 'rails_helper'
require 'ostruct'

describe PsdFormatter do
  let(:deployment_info) { OpenStruct.new(name: application_name, version: '10.3.0', environment: 'test') } # rubocop:todo Metrics/OpenStructUse

  let(:log) { StringIO.new }

  before do
    Rails.logger = Logger.new(log)
    Rails.logger.formatter = described_class.new(deployment_info)
  end

  # These two context handle the temporary need to deploy in two environments
  # Once we are fully of the old metal, we only depend on the 'without application'
  # name behaviour, and should probably use that regardless of whether a name is supplied.

  context 'with an application name' do
    let(:application_name) { 'Sequencescape' }

    it 'formats the log correctly' do
      Rails.logger.info 'info message'
      log.rewind
      expect(log.read).to match(
        # rubocop:todo Layout/LineLength
        /\A\(thread-#{Thread.current.object_id}\) \[#{application_name}:#{deployment_info.version}:#{deployment_info.environment}\]  INFO -- : info message/
        # rubocop:enable Layout/LineLength
      )
    end
  end

  context 'without an application name' do
    let(:application_name) { nil }

    it 'formats the log correctly' do
      Rails.logger.info 'info message'
      log.rewind
      expect(log.read).to match(
        # rubocop:todo Layout/LineLength
        /\A\(thread-#{Thread.current.object_id}\) \[#{deployment_info.version}:#{deployment_info.environment}\]  INFO -- : info message/
        # rubocop:enable Layout/LineLength
      )
    end
  end
end
