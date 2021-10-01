# frozen_string_literal: true

#
# A {CompoundSample} is a join object for samples, creating a parent-child relationship
# useful for pooling samples in such a way that the parent sample represents a larger
# number of child samples in receptacles.
class CompoundSample < ApplicationRecord
  belongs_to :parent, class_name: 'Sample'
  belongs_to :child, class_name: 'Sample'
end
