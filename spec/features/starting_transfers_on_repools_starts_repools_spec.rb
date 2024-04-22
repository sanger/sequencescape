# frozen_string_literal: true

# In low input pipelines, and on re-pooling in the ISC pipeline
# a submission is made on a plate part way down the process. Usually
# this is the LB Lib-PCR XP plate. In keeping with the behaviour
# elsewhere in the pipeline, we need to ensure that the re-pool
# requests get started when the downstream plate is started. Previously
# this behaviour was reliant on the subclass of transfe request,
# TrnasferRequest::InitialTransfer, however this makes assumptions about
# plates in the pipeline which can no longer be relied upon, and furthermore
# is painful to handle through transfer request collections, as nested
# attributes do not play well with single table inheritance.

# Unfortunately all this happens as the same time as we're re-factoring transfer requests
# intent is to eliminate the need for initial transfer requests in the
# more advance branch.

require 'rails_helper'

describe 'Starting transfers on repools starts repools' do
  let(:original_input_plate) { create(:input_plate_for_pooling) }
  let(:secondary_input_plate) do
    plate = PlateCreation.create!(user:, parent: original_input_plate, child_purpose: create(:plate_purpose)).child
    create(:transfer_between_plates, source: original_input_plate, destination: plate)
    plate
  end

  let(:target_plate) do
    PlateCreation.create!(user:, parent: original_input_plate, child_purpose: create(:plate_purpose)).child
  end

  let(:user) { create(:user) }

  let(:source_a1) { secondary_input_plate.wells.detect { |w| w.map_description == 'A1' } }
  let(:source_b1) { secondary_input_plate.wells.detect { |w| w.map_description == 'B1' } }
  let(:target_a1) { target_plate.wells.detect { |w| w.map_description == 'A1' } }
  let(:target_b1) { target_plate.wells.detect { |w| w.map_description == 'B1' } }

  let(:library_creation_request_a1) { create(:library_creation_request, asset: source_a1) }
  let(:library_creation_request_b1) { create(:library_creation_request, asset: source_b1) }

  before do
    allow(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode), build(:plate_barcode))
    TransferRequestCollection.create!(
      user:,
      transfer_requests_attributes: [
        { asset: source_a1, target_asset: target_a1, submission: library_creation_request_a1.submission },
        { asset: source_b1, target_asset: target_b1, submission: library_creation_request_b1.submission }
      ]
    )
  end

  it 'The target plate is started' do
    StateChange.create(user:, target: target_plate, target_state: 'started')
    expect(library_creation_request_a1.reload).to be_started
    expect(library_creation_request_b1.reload).to be_started
  end
end
