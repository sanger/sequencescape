# frozen_string_literal: true

# Privileges granted to users with the lab_manager role
class Ability::LabManager
  include CanCan::Ability

  prepend Ability::Shared::LabUser

  attr_reader :user

  def initialize(user)
    @user = user
    grant_privileges
  end

  private

  def grant_privileges
    Rails.logger.debug { 'Granting LabManager privileges' }

    can :edit, Labware
    can :change_purpose, Labware
    can :change_priority, [Request, Submission]
    can :update_priority, [Pipeline] # Really should be on request

    # Whether the inbox shows if a request is previously failed
    can :see_previously_failed, Request
    can :cancel, Submission
  end
end
