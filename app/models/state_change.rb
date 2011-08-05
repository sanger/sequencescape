# Performs a change of state on an asset.
#
#--
# This code assumes that there is no statemachine on the requests.  Whilst this is not true it will be in the
# future and we are safe to assume that, in the case of Pulldown, this is ok.  The state of a plate, or the MX
# library tube, in Pulldown is considered to be the state of the TransferRequests leading into it.  The state
# machine for the asset is defined within the client application, hence the statemachine on the requests will
# be removed from the core of sequencescape at some point.
#++
class StateChange < ActiveRecord::Base
  include Uuid::Uuidable

  belongs_to :user
  validates_presence_of :user

  # This is the target asset for which to update the state
  belongs_to :target, :class_name => 'Asset'
  validates_presence_of :target

  # Some targets can have "contents" updated (notably plates).  The meaning of this is is dealt with by the
  # target being updated.
  serialize :contents

  # These track the state of the target.  The target_state is what we want it to end up in and the previous_state
  # records the state that it was in before the update.  The previous_state is not assigned by the creator but
  # by the action of making the transition.
  validates_inclusion_of :target_state,   :in => %w{pending started passed failed cancelled}
  validates_unassigned(:previous_state)

  # Before creating an instance we record the current state of the target.
  before_create :record_current_state_of_target
  def record_current_state_of_target
    self.previous_state = target.state
  end
  private :record_current_state_of_target

  # After creation update the state of the target asset, leaving it to do the right thing.
  after_create :update_state_of_target
  def update_state_of_target
    target.transition_to(target_state, contents)
  end
  private :update_state_of_target
end
