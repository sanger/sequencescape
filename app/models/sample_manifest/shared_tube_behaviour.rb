module SampleManifest::SharedTubeBehaviour
  def generate_tubes(purpose)
    sanger_ids = generate_sanger_ids(count)
    study_abbreviation = study.abbreviation

    tubes = []
    count.times do
      tube = purpose.create!
      sanger_sample_id = SangerSampleId.generate_sanger_sample_id!(study_abbreviation, sanger_ids.shift)
      SampleManifestAsset.create!(sanger_sample_id: sanger_sample_id,
                                  asset: tube.receptacle,
                                  sample_manifest: self)
      tubes << tube
    end

    self.barcodes = tubes.map(&:human_barcode)

    delayed_generate_asset_requests(tubes.map(&:id), study.id)
    save!
    tubes
  end

  def build_sample_and_aliquot(sanger_sample_id, tube)
    tube_sample_creation(sanger_sample_id, tube)
  end

  def delayed_generate_asset_requests(asset_id, study_id)
    Delayed::Job.enqueue GenerateCreateAssetRequestsJob.new([asset_id], study_id)
  end

  private

  def tube_sample_creation(sanger_sample_id, tube)
    create_sample(sanger_sample_id).tap do |sample|
      attributes = core_behaviour.assign_library? ? { sample: sample, library_id: tube.id, study: study } : { sample: sample, study: study }
      tube.aliquots.create!(attributes)

      study.samples << sample
    end
  end
end
