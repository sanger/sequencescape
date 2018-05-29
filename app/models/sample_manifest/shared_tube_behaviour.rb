# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.

module SampleManifest::SharedTubeBehaviour
  def generate_tubes(purpose)
    sanger_ids = generate_sanger_ids(count)
    study_abbreviation = study.abbreviation

    tubes, samples_data = [], []
    count.times do |_|
      tube = purpose.create!
      sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)

      tubes << tube
      samples_data << [tube, sanger_sample_id]
    end

    self.barcodes = tubes.map(&:human_barcode)

    tube_sample_creation(samples_data)
    delayed_generate_asset_requests(tubes.map(&:id), study.id)
    save!
    tubes
  end

  def delayed_generate_asset_requests(asset_ids, study_id)
    Delayed::Job.enqueue GenerateCreateAssetRequestsJob.new(asset_ids, study_id)
  end

  private

  def tube_sample_creation(samples_data)
    study.samples << samples_data.map do |tube, sanger_sample_id|
      create_sample(sanger_sample_id).tap do |sample|
        attributes = core_behaviour.assign_library? ? { sample: sample, library_id: tube.id, study: study } : { sample: sample, study: study }
        tube.aliquots.create!(attributes)
      end
    end
  end
end
