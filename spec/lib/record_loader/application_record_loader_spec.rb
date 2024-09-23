# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/application_record_loader'

RSpec.describe RecordLoader::ApplicationRecordLoader, :loader, type: :model do
  def a_new_record_loader
    described_class.new(directory: test_directory)
  end

  subject(:record_loader) { a_new_record_loader }

  let(:test_directory) { Rails.root.join('spec/data/record_loader/application_record_loader') }

  context 'when deploy_wip_pipelines is false' do
    before { allow(Rails.application.config).to receive(:deploy_wip_pipelines).and_return(false) }

    it 'returns an empty array' do
      expect(record_loader.wip_list).to eq([])
    end
  end

  context 'when deploy_wip_pipelines is true' do
    before do
      allow(Rails.application.config).to receive(:deploy_wip_pipelines).and_return(true)
      allow(Find).to receive(:find).with(test_directory).and_yield("#{test_directory}/example.wip.yml")
    end

    it 'returns a list of WIP features' do
      expect(record_loader.wip_list).to eq(['example'])
    end
  end

  context 'when deploy_wip_pipelines is not set' do
    before { allow(Rails.application.config).to receive(:deploy_wip_pipelines).and_return(nil) }

    it 'returns an empty array' do
      expect(record_loader.wip_list).to eq([])
    end
  end
end
