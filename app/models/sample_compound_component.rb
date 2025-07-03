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
end
