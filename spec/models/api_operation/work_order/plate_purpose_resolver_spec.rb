# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::PlatePurposeResolver do
  subject(:resolver) { described_class.new({}, template, requested_receptacles:) }

  let(:template) { instance_double(SubmissionTemplate, name: template_name) }
  let(:template_name) { 'Limber-Htp - LCMB - Illumina-HTP' }
  let(:stock_purpose) { create(:plate_purpose, name: 'Library Stock Plate') }
  let(:plate) { create(:plate_with_untagged_wells, well_count: 1, plate_purpose: stock_purpose) }
  let(:requested_receptacles) { ApiOperation::WorkOrder::RequestedReceptacles.new(["#{plate.human_barcode}:A1"]) }
  let!(:purpose) { create(:plate_purpose, name: 'LCMB Cherrypick') }

  it 'assigns the purpose mapped to the template name, ignoring a platform suffix' do
    resolver.assign!
    expect(plate.reload.plate_purpose).to eq(purpose)
  end

  context 'when the plate is not a Library Stock Plate' do
    let(:plate) { create(:plate_with_untagged_wells, well_count: 1, plate_purpose: create(:plate_purpose)) }

    it 'leaves the plate purpose unchanged' do
      expect { resolver.assign! }.not_to(change { plate.reload.plate_purpose })
    end

    it 'does not consult the mapping' do
      allow(described_class).to receive(:mapping)
      resolver.assign!
      expect(described_class).not_to have_received(:mapping)
    end
  end

  context 'when the template has no mapping' do
    let(:template_name) { 'Unmapped template' }

    it 'leaves the plate purpose unchanged' do
      expect { resolver.assign! }.not_to(change { plate.reload.plate_purpose })
    end
  end

  context 'when the mapped purpose does not exist' do
    before { purpose.destroy }

    it 'raises an error pointing at the requested labware' do
      expect { resolver.assign! }.to raise_error(ApiOperation::Error, /Cannot find plate purpose/)
    end
  end

  context 'when the template maps to several purposes' do
    before { allow(described_class).to receive(:mapping).and_return(template_name => %w[A B]) }

    it 'raises an error' do
      expect { resolver.assign! }.to raise_error(ApiOperation::Error, /single plate purpose/)
    end
  end
end
