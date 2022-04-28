# frozen_string_literal: true
# Despite name controls rendering of warehouse messages for {Project}
# Historically used to be v0.5 API
class Api::ProjectIO < Api::Base
  module Extensions # rubocop:todo Style/Documentation
    module ClassMethods # rubocop:todo Style/Documentation
      def render_class
        Api::ProjectIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json,
              -> { includes([:uuid_object, { project_metadata: %i[project_manager budget_division], roles: :users }]) }
      end
    end
  end

  renders_model(::Project)

  map_attribute_to_json_attribute(:uuid)
  map_attribute_to_json_attribute(:id)
  map_attribute_to_json_attribute(:name)
  map_attribute_to_json_attribute(:approved)
  map_attribute_to_json_attribute(:state)
  map_attribute_to_json_attribute(:created_at)
  map_attribute_to_json_attribute(:updated_at)

  with_association(:project_metadata) do
    with_association(:project_manager, lookup_by: :name) { map_attribute_to_json_attribute(:name, 'project_manager') }
    map_attribute_to_json_attribute(:project_cost_code, 'cost_code')
    map_attribute_to_json_attribute(:funding_comments, 'funding_comments')
    map_attribute_to_json_attribute(:collaborators, 'collaborators')
    map_attribute_to_json_attribute(:external_funding_source, 'external_funding_source')
    with_association(:budget_division, lookup_by: :name) { map_attribute_to_json_attribute(:name, 'budget_division') }
    map_attribute_to_json_attribute(:sequencing_budget_cost_centre, 'budget_cost_centre')
    map_attribute_to_json_attribute(:project_funding_model, 'funding_model')
  end

  extra_json_attributes do |object, json_attributes|
    object.roles.each do |role|
      json_attributes[role.name.underscore] =
        role.users.map { |user| { login: user.login, email: user.email, name: user.name } }
    end
  end
end
