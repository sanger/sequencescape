# frozen_string_literal: true

require 'rails_helper'

describe UatActions::PlateInformation do
  context 'when the plate has aliquots' do
    let(:plate_barcode) { 'SQPD-1' }
    let(:parameters) { { plate_barcode: plate_barcode } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { plate_barcode: plate_barcode, wells_with_aliquots: 'A1, B1, C1', wells_with_active_requests_as_source: '' }
    end

    before { create :plate_with_untagged_wells, sample_count: 3, barcode: plate_barcode }

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
    end
  end

  context 'when the plate is without aliquots' do
    let(:plate_barcode) { 'SQPD-2' }
    let(:parameters) { { plate_barcode: plate_barcode } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { plate_barcode: plate_barcode, wells_with_aliquots: '', wells_with_active_requests_as_source: '' }
    end

    before { create :plate_with_empty_wells, well_count: 3, barcode: plate_barcode }

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
    end
  end

  context 'when the plate barcode does not match a plate' do
    let(:parameters) { { plate_barcode: 'INVALID' } }
    let(:uat_action) { described_class.new(parameters) }
    let(:report) do
      # A report is a hash of key value pairs which get returned to the user.
      # It should include information such as barcodes and identifiers
      { plate_barcode: 'INVALID' }
    end

    it 'cannot be performed' do
      expect(uat_action.perform).to be false
      expect(uat_action.report).to eq report
    end
  end

  # This test is for the scenario where the plate has a partial submission on it.
  # We expect to return the wells that have been submitted (have active requests as source)
  context 'when the plate has a partial submission' do
    let(:plate_barcode) { 'SQPD-3' }
    let(:parameters) { { plate_barcode: plate_barcode } }
    let(:uat_action) { described_class.new(parameters) }
    let(:submission) { create :submission }
    let(:request_type) { create :library_creation_request_type }
    let(:report) do
      { plate_barcode: plate_barcode, wells_with_aliquots: 'A1, B1, C1',
wells_with_active_requests_as_source: 'A1, C1' }
    end

    before do
      plate = create :plate_with_untagged_wells, sample_count: 3, barcode: plate_barcode

      plate_wells = plate.wells.with_contents

      req1 = create :library_creation_request, asset: plate_wells.first, submission: submission,
request_type: request_type, state: 'started'
      plate_wells.first.requests_as_source << req1

      req2 = create :library_creation_request, asset: plate_wells.last, submission: submission,
request_type: request_type, state: 'started'
      plate_wells.last.requests_as_source << req2
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
    end
  end

  # This test is for a scenario where there there is a previous (now closed) submission on the wells ONLY
  # i.e. only want wells with ACTIVE requests as source so this should not return any wells
  context 'when the plate has a closed submission' do
    let(:plate_barcode) { 'SQPD-4' }
    let(:parameters) { { plate_barcode: plate_barcode } }
    let(:uat_action) { described_class.new(parameters) }
    let(:submission) { create :submission }
    let(:request_type) { create :library_creation_request_type }
    let(:report) do
      { plate_barcode: plate_barcode, wells_with_aliquots: 'A1, B1, C1', wells_with_active_requests_as_source: '' }
    end

    before do
      plate = create :plate_with_untagged_wells, sample_count: 3, barcode: plate_barcode

      plate_wells = plate.wells.with_contents

      req1 = create :library_creation_request, asset: plate_wells.first, submission: submission,
request_type: request_type, state: 'passed'
      plate_wells.first.requests_as_source << req1

      req2 = create :library_creation_request, asset: plate_wells.last, submission: submission,
request_type: request_type, state: 'passed'
      plate_wells.last.requests_as_source << req2
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
    end
  end

  # This test is for the scenario where we have both an old submission and a new submission on the plate (different
  # subsets of wells) - we expect to only return the wells with the new (active) submission
  context 'when the plate has both active and closed submissions' do
    let(:plate_barcode) { 'SQPD-4' }
    let(:parameters) { { plate_barcode: plate_barcode } }
    let(:uat_action) { described_class.new(parameters) }
    let(:submission) { create :submission }
    let(:submission2) { create :submission }
    let(:request_type) { create :library_creation_request_type }
    let(:report) do
      { plate_barcode: plate_barcode, wells_with_aliquots: 'A1, B1, C1',
wells_with_active_requests_as_source: 'A1, C1' }
    end

    before do
      plate = create :plate_with_untagged_wells, sample_count: 3, barcode: plate_barcode

      plate_wells = plate.wells.with_contents

      req1 = create :library_creation_request, asset: plate_wells.first, submission: submission,
request_type: request_type, state: 'passed'
      plate_wells.first.requests_as_source << req1

      req2 = create :library_creation_request, asset: plate_wells.second, submission: submission,
request_type: request_type, state: 'passed'
      plate_wells.second.requests_as_source << req2

      req3 = create :library_creation_request, asset: plate_wells.last, submission: submission,
request_type: request_type, state: 'passed'
      plate_wells.last.requests_as_source << req3

      req4 = create :library_creation_request, asset: plate_wells.first, submission: submission2,
request_type: request_type, state: 'started'
      plate_wells.first.requests_as_source << req4

      req5 = create :library_creation_request, asset: plate_wells.last, submission: submission2,
request_type: request_type, state: 'started'
      plate_wells.last.requests_as_source << req5
    end

    it 'can be performed' do
      expect(uat_action.perform).to be true
      expect(uat_action.report).to eq report
    end
  end

  it 'returns a default' do
    expect(described_class.default).to be_a described_class
  end
end
