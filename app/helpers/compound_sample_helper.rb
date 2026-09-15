# frozen_string_literal: true

module CompoundSampleHelper
  def find_or_create_compound_sample(study, component_samples)
    #  Check if a compound sample already exists with the component samples
    find_compound_sample_for_component_samples(component_samples) ||
      create_compound_sample_with_components(study, component_samples)
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

  # Returns the supplier name shared by all source aliquots, if they are consistent.
  #
  # @return [String, nil] the supplier name if all source aliquots share the same one; nil otherwise
  def extract_consistent_supplier_name_from_source_aliquots
    supplier_names = (@source_aliquots || []).map(&:sample).map(&:sample_metadata).map(&:supplier_name).uniq
    return unless supplier_names.length == 1

    supplier_names.first
  end

  # Generates the compound sample
  def create_compound_sample_with_components(study, component_samples)
    ActiveRecord::Base.transaction do
      compound_sample = create_compound_sample(study)
      create_component_samples_for_compound(compound_sample, component_samples)
      compound_sample
    end
  end

  def create_compound_sample(study)
    supplier_name = extract_consistent_supplier_name_from_source_aliquots
    study.samples.create!(
      name: SangerSampleId.generate_sanger_sample_id!(study.abbreviation),
      supplier_name: supplier_name
    )
  end

  # using insertAll to avoid N queries for 9k samples, as we are already in a transaction and will
  # roll back if any validation fails
  # rubocop:disable-next Rails/SkipsModelValidations
  def create_component_samples_for_compound(compound_sample, component_samples)
    validation_errors = SampleCompoundComponent.bulk_validate_component_samples(component_samples)
    if validation_errors.any?
      compound_sample.errors.add(:base, validation_errors.join('; '))
      raise ActiveRecord::RecordInvalid, compound_sample
    end
    SampleCompoundComponent.insert_all(component_samples.map do |s|
      { compound_sample_id: compound_sample.id, component_sample_id: s.id }
    end)
  end
end
