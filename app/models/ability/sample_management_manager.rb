# frozen_string_literal: true

# Privileges granted to users with the slf_manager role
class Ability::SampleManagementManager
  include CanCan::Ability

  prepend Ability::Shared::SampleManagementUser

  attr_reader :user

  def initialize(user)
    @user = user
    grant_privileges
  end

  private

  def grant_privileges
    Rails.logger.debug { 'Granting SampleManagementManager' }
    can :create, SampleManifest
    can :create, Supplier
    can :manage, PlateTemplate
    can :convert_to_tube, Plate
    can :cancel, Submission
  end
end
