# frozen_string_literal: true

require 'rails_helper'
require 'record_loader/ultima_primer_loader'

RSpec.describe RecordLoader::UltimaPrimerLoader, :loader, type: :model do
  subject(:record_loader) do
    described_class.new(directory: test_directory, files: nil)
  end

  let(:test_directory) { Rails.root.join('spec/data/record_loader/ultima_primers') }

  it 'loads records from every YAML file', :aggregate_failures do
    expect { record_loader.create! }.to change(UltimaPrimer, :count).by(2)

    expect(UltimaPrimer.pluck(:name)).to contain_exactly(
      'UGA primer 1',
      'UGB primer 1'
    )
  end

  it 'is idempotent' do
    record_loader.create!

    expect { record_loader.create! }.not_to change(UltimaPrimer, :count)
  end
end
