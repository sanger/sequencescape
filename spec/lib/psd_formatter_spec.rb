require 'rails_helper'
require 'ostruct'

describe PsdFormatter do
  let(:deployment_info) do
    OpenStruct.new(
      name: 'Sequencescape',
      version: '10.3.0',
      environment: 'test'
    )
  end

  let(:log) { StringIO.new }

  setup do
    Rails.logger = Logger.new(log)
    Rails.logger.formatter = PsdFormatter.new(deployment_info)
  end

  it 'formats the log correctly' do
    Rails.logger.info 'info message'
    log.rewind
    expect(log.read).to match(/\A\(thread-#{Thread.current.object_id}\) \[#{deployment_info.version}:#{deployment_info.environment}\]  INFO -- : info message/)
  end
end
