# frozen_string_literal: true

# Privileges granted to users with the sfl_gel role
class Ability::SampleManagementGel
  include CanCan::Ability

  prepend Ability::Shared::SampleManagementUser

  attr_reader :user

  def initialize(user)
    @user = user
    grant_privileges
  end

  private

  def grant_privileges
    # No special Privileges beyond those in Ability::Shared::SampleManagementUser
  end
end
