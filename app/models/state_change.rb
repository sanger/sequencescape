# frozen_string_literal: true

# Performs a change of state on a {Labware}.
#
#--
# This code assumes that there is no statemachine on the requests.  Whilst this is not true it will be in the
# future and we are safe to assume that, in the case of Pulldown, this is ok.  The state of a plate, or the MX
# library tube, in Pulldown is considered to be the state of the TransferRequests leading into it.  The state
# machine for the asset is defined within the client application, hence the statemachine on the requests will
# be removed from the core of sequencescape at some point.
#++
class StateChange < ApplicationRecord
  include Uuid::Uuidable
  include Asset::Ownership::ChangesOwner

  attr_accessor :customer_accepts_responsibility

  belongs_to :user, optional: false

  # This is the target asset for which to update the state
  belongs_to :target, class_name: 'Labware', optional: false

  # Some targets can have "contents" updated (notably plates).  The meaning of this is is dealt with by the
  # target being updated.
  serialize :contents, coder: YAML

  # If the state change is a known failure state then a reason must be included
  validates :reason, presence: true, if: :targetted_for_failure?

  # These track the state of the target.  The target_state is what we want it to end up in and the previous_state
  # records the state that it was in before the update.  The previous_state is not assigned by the creator but
  # by the action of making the transition.
  validates :target_state, presence: true
  validates_unassigned :previous_state

  # If we don't have a state changer configured, we can't change the state
  validates :state_changer,
            presence: {
              message: 'target does not have a configured state changer'
            },
            unless: -> { target.nil? }

  before_create :record_current_state_of_target
  after_create :update_state_of_target

  set_target_for_owner(:target)

  private

  def targetted_for_failure?
    %w[failed cancelled].include?(target_state)
  end

  # Before creating an instance we record the current state of the target.
  def record_current_state_of_target
    self.previous_state = target.state
  end

  # state_changer is set as a class-level variable in each purpose.
  # For an example, see, app/models/tube_rack/purpose.rb.
  def state_changer
    target.state_changer
  end

  # After creation update the state of the target asset, leaving it to do the right thing.
  # After state change, update the owner
  def update_state_of_target
    state_changer.new(
      labware: target,
      target_state: target_state,
      user: user,
      contents: contents,
      customer_accepts_responsibility: customer_accepts_responsibility
    ).update_labware_state
  end
end
