# frozen_string_literal: true

# Any model that turns component samples into a compound sample is considered compoundable.
module Sample::Compoundable
  MULTIPLE_STUDIES_ERROR_MSG =
    'Cannot create compound sample due to the component samples being under different studies.'

  def self.included(base)
    base.class_eval do
      attr_accessor :request, :component_samples
      attr_reader :compound_sample

      validate :component_samples_have_same_study
    end
  end

  def component_samples_have_same_study
    return if request.initial_study || component_samples.map(&:study_ids).uniq.count == 1

    errors.add(:base, "#{MULTIPLE_STUDIES_ERROR_MSG}: #{component_samples.map(&:name)}")
  end

  def find_or_create_compound_sample
    #  Check if a compound sample already exists with the component samples
    existing_compound_sample = find_compound_sample_for_component_samples

    @compound_sample = existing_compound_sample || create_compound_sample
  end

  # Due to previous implementation, there may be multiple compound samples with the provided component samples.
  # NPG have confirmed we do not need to fix the data where there are multiple compound samples with
  # the same component samples
  def find_compound_sample_for_component_samples
    # Get all the compound samples of the first component sample
    # .includes eager loads the component_samples upfront, otherwise you risk lots of hits to the database.
    compound_samples = component_samples.first.compound_samples.includes(:component_samples).order(id: :desc)

    # Find the latest compound sample which contains the given component samples
    compound_samples.find { |compound_sample| compound_sample.component_samples == component_samples }
  end

  # Generates the compound sample, under the default study, using the component samples
  def create_compound_sample
    default_compound_study.samples.create!(
      name: SangerSampleId.generate_sanger_sample_id!(default_compound_study.abbreviation),
      component_samples: component_samples
    )
  end

  # Study: Use the one from the request if present, otherwise use the first one from the component samples.
  # If the component samples are from different studies, an error will be added to the model.
  def default_compound_study
    request.initial_study || component_samples.first.studies.first
  end
end
