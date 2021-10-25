# frozen_string_literal: true
module Request::SampleCompoundAliquotTransfer
  def compound_samples_needed?
    asset.aliquots.any? {|al| !al.tag_depth.nil? }
  end

  def transfer_aliquots_into_compound_sample_aliquot
    compound_sample = _create_compound_sample(_default_compound_study, asset.samples)
    target_asset.aliquots.create(sample: compound_sample).tap do |aliquot|
      aliquot.study_id = _default_compound_study.id
      aliquot.project_id = _default_compound_project_id
      aliquot.save
    end
  end

  private

  def _create_compound_sample(study, component_samples)
    study.samples.create!(
      name: SangerSampleId.generate_sanger_sample_id!(study.abbreviation), 
      component_samples: component_samples
    )
  end

  def _default_compound_study
    asset.samples.first.studies.first
  end

  def _default_compound_project_id
    asset.aliquots.first.project_id
  end

end
