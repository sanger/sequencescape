# frozen_string_literal: true

#
# A {CompoundSample} is a join object for samples, creating a parent-child relationship
# useful for pooling samples in such a way that the parent sample represents a larger
# number of child samples in receptacles.
class CompoundSample < ApplicationRecord
  belongs_to :parent, foreign_key: 'parent_id', class_name: 'Sample'
  belongs_to :child, foreign_key: 'child_id', class_name: 'Sample'
end
