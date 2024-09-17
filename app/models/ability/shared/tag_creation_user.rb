# frozen_string_literal: true

# Prepend to an ability class to include Tag Creation User privileges
# Govern the ability to create tag groups, layouts and sets
module Ability::Shared::TagCreationUser
  def grant_privileges
    super

    # More advanced user administration, such as the ability to add
    # and remove roles
    Rails.logger.debug { 'Granting TagCreationUser privileges' }
    can :manage, TagGroup
    can :manage, TagLayoutTemplate
    can :manage, TagSet
  end
end
