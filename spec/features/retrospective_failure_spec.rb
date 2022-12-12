# frozen_string_literal: true

require 'rails_helper'

describe 'Retrospective failure' do
  # Occasionally users fail a well after additional work has been done
  # on it. This is usually because they forgot to fail the well
  # at the appropriate stage, although may also happen if additional information
  # comes to light later.
  #
  # When this occurs we need to walk downstream and remove matching aliquots.
  # An aliquot can be though of as matching when either:
  # 1) Its sample, tag, tag2, library id all match its immediate ancestor.
  # 2) The sample id matches and the other fields have been set for the first time
  #   (ie. were nil on the ancestor)
  #
  # Exception: When conducting QC, particularly MiSeq QC, we do not wish to retrospectively
  # remove aliquots form the QC tube or its descendants, as it is this QC process which
  # informed the QC decision. The sample should still be considered to be present.
  #
  # Limitations: In an ideal world we'd probably want the following behaviour:
  # 1) Failures on plates upstream of the plate from with the MiSeq tubes are made would still
  #    result in aliquots being removed from the QC tubes.
  # 2) Aliquots would not get removed from other QC plates.
  # However in practice these situations occur so rarely, and failure to handle them has
  # minimal consequence, that the additional code complexity outweighs the minor benefits.

  # The well we'll be failing
  let(:target_well) { create :untagged_well }

  # The actual request that gets failed.
  let(:target_request) { create :transfer_request, target_asset: target_well }
  let(:initial_aliquot) { target_well.aliquots.first }
  let(:tag) { create :tag }
  let(:tag2) { create :tag }

  context 'with two descendants and one clash' do
    let(:child_well_1) { create :empty_well }

    let(:child_well_2) do
      well = create :empty_well
      well.aliquots << create(:tagged_aliquot, receptacle: well, sample: initial_aliquot.sample)
      well
    end

    before do
      # NOTE: These transfer requests automatically handle the transfer of our aliquot.
      create :transfer_request, asset: target_well, target_asset: child_well_1

      # Apply tags to make sure that gets handled correctly
      child_well_1.aliquots.first.tap do |aliquot|
        aliquot.tag = tag
        aliquot.save!
      end
      create :transfer_request, asset: child_well_1, target_asset: child_well_2

      # Just double check that the setup has worked as intended
      expect(child_well_2.aliquots.count).to eq(2)
    end

    it 'fail removed downstream aliquots' do
      target_request.fail!
      successes, failures = Delayed::Worker.new.work_off

      # We don't remove the aliquot from the failed well itself
      expect(target_well.aliquots.count).to eq(1)

      # We don't remove the aliquot from the failed well itself
      expect(child_well_1.aliquots.count).to eq(0)

      # Non matching aliquots downstream are left untouched
      expect(child_well_2.aliquots.count).to eq(1)
      expect(child_well_2.aliquots.first.tag).not_to eq(tag)
    end
  end

  context 'with a QcTube descendant' do
    let(:child_well_1) { create :empty_well }

    let(:qc_tube) { create :qc_tube }

    let(:lane) { create :lane }

    before do
      # NOTE: These transfer requests automatically handle the transfer of our aliquot.
      create :transfer_request, asset: target_well, target_asset: child_well_1
      create :transfer_request, asset: target_well, target_asset: qc_tube
      create :transfer_request, asset: qc_tube, target_asset: lane
    end

    it 'fail removed downstream aliquots' do
      target_request.fail!
      successes, failures = Delayed::Worker.new.work_off

      # We don't remove the aliquot from the failed well itself
      expect(target_well.aliquots.count).to eq(1)

      # We don't remove the aliquot from the failed well itself
      expect(child_well_1.aliquots.count).to eq(0)

      # But we don't touch the aliquots in the qc tube or its lanes.
      expect(qc_tube.aliquots.count).to eq(1)
      expect(lane.aliquots.count).to eq(1)
    end
  end
end
