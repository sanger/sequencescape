module SampleManifest::SharedTubeBehaviour
  def generate_tubes(purpose)
    sanger_ids = generate_sanger_ids(count)
    study_abbreviation = study.abbreviation

    tubes, samples_data = [], []
    count.times do |_|
      tube = purpose.create!
      sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)
      SampleManifestAsset.create(sanger_sample_id: sanger_sample_id,
                                 asset: tube,
                                 sample_manifest: self)
      tubes << tube
      samples_data << [tube, sanger_sample_id]
    end

    self.barcodes = tubes.map(&:human_barcode)

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
