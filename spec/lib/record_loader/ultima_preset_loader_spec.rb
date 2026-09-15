# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/ultima_preset_loader'

RSpec.describe RecordLoader::UltimaPresetLoader, :loader, type: :model do
  subject(:record_loader) do
    described_class.new(directory: test_directory, files: nil)
  end

  let(:test_directory) { Rails.root.join('spec/data/record_loader/ultima_presets') }

  it 'loads records from every YAML file', :aggregate_failures do
    expect { record_loader.create! }.to change(UltimaPreset, :count).by(2)

    expect(UltimaPreset.pluck(:name)).to contain_exactly(
      'UG100 preset 1',
      'UG200 preset 1'
    )
  end

  it 'is idempotent' do
    record_loader.create!

    expect { record_loader.create! }.not_to change(UltimaPreset, :count)
  end
end
