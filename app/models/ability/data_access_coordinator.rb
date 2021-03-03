# frozen_string_literal: true

# Privileges granted to users with the lab_manager role
class Ability::DataAccessCoordinator
  include CanCan::Ability

  attr_reader :user

  def initialize(user)
    @user = user
    grant_privileges
  end

  private

  def grant_privileges
    Rails.logger.debug { 'Granting DataAccessCoordinator privileges' }
    can :change_ethically_approved, Study
  end
end
