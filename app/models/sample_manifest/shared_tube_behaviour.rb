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
    (0...count).each do |_|
      tube = purpose.create!
      sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)

      tubes << tube
      samples_data << [tube.barcode, sanger_sample_id, tube.prefix]
    end

    self.barcodes = tubes.map(&:sanger_human_barcode)

    tube_sample_creation(samples_data, study.id)
    delayed_generate_asset_requests(tubes.map(&:id), study.id)
    save!
    tubes
  end

  def delayed_generate_asset_requests(asset_ids, study_id)
    Delayed::Job.enqueue GenerateCreateAssetRequestsJob.new(asset_ids, study_id)
  end

  def tube_sample_creation(samples_data, _study_id)
    study.samples << samples_data.map do |barcode, sanger_sample_id, _prefix|
      create_sample(sanger_sample_id).tap do |sample|
        sample_tube = Tube.find_by(barcode: barcode) or raise ActiveRecord::RecordNotFound, "Cannot find sample tube with barcode #{barcode.inspect}"
        sample_tube.aliquots.create!(sample: sample)
      end
    end
  end
  private :tube_sample_creation
end
