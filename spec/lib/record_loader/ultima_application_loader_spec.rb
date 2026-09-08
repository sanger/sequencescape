# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/ultima_application_loader'

RSpec.describe RecordLoader::UltimaApplicationLoader, :loader, type: :model do
  subject(:record_loader) do
    described_class.new(directory: test_directory, files: nil)
  end

  let(:test_directory) { Rails.root.join('spec/data/record_loader/ultima_applications') }

  let(:ug100_preset_attributes) do
    { name: 'UG100 preset 1', application_type: 'UG100_app_type_1', sequencing_recipe: 'SR100_1' }
  end
  let(:ug200_preset_attributes) do
    { name: 'UG200 preset 1', application_type: 'UG200_app_type_1', sequencing_recipe: 'SR200_1' }
  end
  let(:uga_primer_attributes) do
    { name: 'UGA primer 1' }
  end
  let(:ugb_primer_attributes) do
    { name: 'UGB primer 1' }
  end

  before do
    UltimaPreset.create!(ug100_preset_attributes)
    UltimaPreset.create!(ug200_preset_attributes)
    UltimaPrimer.create!(uga_primer_attributes)
    UltimaPrimer.create!(ugb_primer_attributes)
  end

  it 'resolves named presets and primers into associations', :aggregate_failures do
    expect { record_loader.create! }.to change(UltimaApplication, :count).by(1)

    application = UltimaApplication.find_by!(name: 'Test application')

    expect(application).to have_attributes(
      description: 'Test description',
      ug100_preset: have_attributes(ug100_preset_attributes),
      ug200_preset: have_attributes(ug200_preset_attributes),
      uga_primer: have_attributes(uga_primer_attributes),
      ugb_primer: have_attributes(ugb_primer_attributes)
    )
  end

  it 'is idempotent' do
    record_loader.create!

    expect { record_loader.create! }.not_to change(UltimaApplication, :count)
  end

  it 'raises when a named association does not exist' do
    UltimaPrimer.find_by!(name: uga_primer_attributes[:name]).destroy!

    expect { record_loader.create! }.to raise_error(
      StandardError,
      /Failed to create Test application due to: Couldn't find UltimaPrimer/
    )
  end
end
