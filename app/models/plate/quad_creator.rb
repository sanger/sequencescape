# frozen_string_literal: true

# require 'lib/nested_validators'
# The Quad creator takes 4 parent 96 well plates or size 96 tube-racks
# and transfers them onto a new 384 well plate
class Plate::QuadCreator
  extend NestedValidation
  include ActiveModel::Model

  attr_accessor :parents, :target_purpose, :user

  validates_nested :creation

  # Rubocop is unhappy, but we'll be extending this method shortly
  # rubocop:disable Rails/Delegate
  def save
    creation.save
  end
  # rubocop:enable Rails/Delegate

  def creation
    @creation ||= PooledPlateCreation.new(user: user, parents: parents.values, child_purpose: target_purpose)
  end

  def target_plate
    @creation.child
  end
end
