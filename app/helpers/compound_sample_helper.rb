# frozen_string_literal: true

module CompoundSampleHelper
  def find_or_create_compound_sample(study, component_samples)
    #  Check if a compound sample already exists with the component samples
    find_compound_sample_for_component_samples(component_samples) || create_compound_sample(study, component_samples)
  end

  private

  # Due to previous implementation, there may be multiple compound samples with the provided component samples.
  # NPG have confirmed we do not need to fix the data where there are multiple compound samples with
  # the same component samples
  def find_compound_sample_for_component_samples(component_samples)
    # Get all the compound samples of the first component sample
    # .includes eager loads the component_samples upfront, otherwise you risk lots of hits to the database.
    compound_samples = component_samples.first.compound_samples.includes(:component_samples).order(id: :desc)

    # Find the latest compound sample which contains the given component samples
    compound_samples.find { |compound_sample| compound_sample.component_samples == component_samples }
  end

  # Generates the compound sample
  def create_compound_sample(study, component_samples)
    study.samples.create!(
      name: SangerSampleId.generate_sanger_sample_id!(study.abbreviation),
      component_samples: component_samples
    )
  end
end
