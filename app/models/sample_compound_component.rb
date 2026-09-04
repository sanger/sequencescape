# frozen_string_literal: true

#
# A {SampleCompoundComponent} is a join object for samples, creating a relationship
# useful for pooling samples in such a way that the compound sample represents a larger
# number of component samples in receptacles.
class SampleCompoundComponent < ApplicationRecord
  self.table_name = 'sample_compounds_components'

  belongs_to :compound_sample, class_name: 'Sample', touch: true
  belongs_to :component_sample, class_name: 'Sample', touch: true

  validate :nested_compound_samples_validation
  validate :nested_component_samples_validation

  def nested_compound_samples_validation
    return if compound_sample.compound_samples.empty?

    errors.add(:compound_sample, 'cannot have further compound samples.')
  end

  def nested_component_samples_validation
    return if component_sample.component_samples.empty?

    errors.add(:component_sample, 'cannot have further component samples.')
  end

  # Bulk validation to be called before insert_all the component samples in CompoundSampleHelper#create_compound_sample
  # Avoids running N queries for 9k samples by doing set-based checks.
  # No need to check if the compound sample is already a compound sample, as it is created in the same transaction and
  #   will not have any component samples yet.
  def self.bulk_validate_component_samples(component_samples)
    errors = []
    invalid_component_ids = SampleCompoundComponent.where(compound_sample_id: component_samples.map(&:id))
      .pluck(:compound_sample_id).uniq
    if invalid_component_ids.any?
      errors << "Component samples #{invalid_component_ids.join(', ')} cannot have further component samples."
    end
    errors
  end
end
