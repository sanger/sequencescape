# frozen_string_literal: true

# Prepend to an ability class to include Lab User privileges
module Ability::Shared::LabUser
  def grant_privileges
    super
    Rails.logger.debug { 'Granting LabUser privileges' }
    can :print_asset_group_labels, Study
  end
end
