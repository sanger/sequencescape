# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::RequestedReceptacles do
  subject(:requested) { described_class.new(identifiers) }

  let(:study) { create(:study) }
  let(:plate) { create(:plate_with_untagged_wells, well_count: 2, studies: [study]) }
  let(:identifiers) { ["#{plate.human_barcode}:A1", "#{plate.human_barcode}:B1", 'NOPE'] }

  it 'finds the receptacles named, skipping those it cannot find' do
    expect(requested.receptacles).to eq(plate.wells.located_at(%w[A1 B1]).to_a.sort_by { |w|
      %w[A1 B1].index(w.map_description)
    })
  end

  it 'pairs each found receptacle with its identifier' do
    expect(requested.identified_receptacles.map(&:first)).to eq(identifiers.first(2))
  end

  it 'reports an error for each identifier it cannot use, pointing at its index' do
    expect(requested.errors.map(&:pointer)).to eq(['/work_order/requested_labware_identifiers/2'])
  end

  it 'lists each plate once' do
    expect(requested.plates).to eq([plate])
  end

  it 'groups the receptacles by their study' do
    expect(requested.receptacles_by_study.keys).to eq([study])
  end

  context 'when a receptacle has no study' do
    before { plate.wells.each { |well| well.aliquots.each { |aliquot| aliquot.update!(study: nil) } } }

    it 'reports each receptacle without exactly one study' do
      expect(requested.study_errors.size).to eq(2)
    end

    it 'leaves them out of the groups' do
      expect(requested.receptacles_by_study).to be_empty
    end
  end
end
