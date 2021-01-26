# frozen_string_literal: true

# Prepend to an ability class to include abilities related to sample
# management roles. Mainly control access to their pipelines
module Ability::Shared::SampleManagementUser
  def grant_privileges
    super
    Rails.logger.debug { 'Granting SampleManagementUser privileges' }
    # Index page of a few sample management tasks
    can :read, SampleLogisticsController
    # Old gels controller.
    can :manage, GelsController
  end
end
