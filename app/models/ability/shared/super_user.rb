# frozen_string_literal: true

# Prepend to an ability class to include SUper User privileges
# These privileges should be restricted to PSD only in future
# Currently awarded to all admins
module Ability::Shared::SuperUser
  def grant_privileges
    super

    # More advanced user administration, such as the ability to add
    # and remove roles
    Rails.logger.debug { 'Granting SuperUser privileges' }

    can :manage, User

    # Changing help text
    can :manage, CustomText

    # Can edit existing plate purposes
    can :manage, [Purpose, PlatePurpose]
    can :manage, PlateTemplate
    can :manage, [Robot, RobotProperty]
    can :manage, FacultySponsor
    can :manage, ReferenceGenome
    can :manage, Role
    can %i[activate deactivate], Pipeline
    can :read, Ability
  end
end
