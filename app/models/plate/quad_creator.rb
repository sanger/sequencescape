# frozen_string_literal: true

# require 'lib/nested_validators'
# The Quad creator takes 4 parent 96 well plates or size 96 tube-racks
# and transfers them onto a new 384 well plate
class Plate::QuadCreator
  extend NestedValidation
  include ActiveModel::Model

  attr_accessor :parents, :target_purpose, :user

  validates_nested :creation

  def save
    creation.save && transfer_request_collection.save
    true
  end

  def target_plate
    @creation.child
  end

  private

  def creation
    @creation ||= PooledPlateCreation.new(user: user, parents: parents.values, child_purpose: target_purpose)
  end

  def transfer_request_collection
    @transfer_request_collection ||= TransferRequestCollection.new(
      user: user,
      transfer_requests_attributes: transfer_requests_attributes
    )
  end

  def transfer_requests_attributes
    # Logic for quad stamping.
    []
  end
end
