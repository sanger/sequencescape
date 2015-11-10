#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2013,2015 Genome Research Ltd.
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

  # If the state change is a known failure state then a reason must be included
  validates_presence_of :reason, :if => :targetted_for_failure?

  def targetted_for_failure?
    [ 'failed', 'cancelled' ].include?(target_state)
  end
  private :targetted_for_failure?

  include Asset::Ownership::ChangesOwner
  set_target_for_owner(:target)

  # Some targets can have "contents" updated (notably plates).  The meaning of this is is dealt with by the
  # target being updated.
  serialize :contents

  attr_accessor :customer_accepts_responsibility

  # These track the state of the target.  The target_state is what we want it to end up in and the previous_state
  # records the state that it was in before the update.  The previous_state is not assigned by the creator but
  # by the action of making the transition.
  validates_presence_of :target_state
  validates_unassigned(:previous_state)

  # Before creating an instance we record the current state of the target.
  before_create :record_current_state_of_target
  def record_current_state_of_target
    self.previous_state = target.state
  end
  private :record_current_state_of_target

  # After creation update the state of the target asset, leaving it to do the right thing.
  # After state change, update the owner
  after_create :update_state_of_target
  def update_state_of_target
    target.transition_to(target_state, user, contents, customer_accepts_responsibility)
  end
  private :update_state_of_target
end
