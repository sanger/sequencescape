# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'studies/asset_groups/show.html.erb' do
  let(:study) { create(:study) }
  # A well of a plate whose only barcode is an external one without a
  # number, as Sapio reception creates (Y26-283)
  let(:plate) do
    plate = create(:plate_with_untagged_wells, sample_count: 1)
    plate.barcodes.delete_all
    plate.barcodes.create!(format: :external, barcode: 'SAPIO-PLATE')
    plate.reload
  end
  let(:asset_group) do
    create(:asset_group, study: study, assets: [plate.wells.first])
  end

  before do
    assign(:study, study)
    assign(:asset_group, asset_group)
    allow(view).to receive(:can?).and_return(false)
    render
  end

  it 'shows the whole barcode' do
    expect(rendered).to include('Barcode: SAPIO-PLATE')
  end
end
