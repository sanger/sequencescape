#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
class Api::ProjectIO < Api::Base
  module Extensions
    module ClassMethods
      def render_class
        Api::ProjectIO
      end
    end

    def self.included(base)
      base.class_eval do
        extend ClassMethods

        scope :including_associations_for_json, -> { includes([
            :uuid_object, {
              :project_metadata => [ :project_manager, :budget_division ],
              :roles => :users
            }
          ])}
      end
    end

    def related_resources
      ['studies']
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
    with_association(:project_manager, :lookup_by => :name) do
      map_attribute_to_json_attribute(:name , 'project_manager')
    end
    map_attribute_to_json_attribute(:project_cost_code , 'cost_code')
    map_attribute_to_json_attribute(:funding_comments , 'funding_comments')
    map_attribute_to_json_attribute(:collaborators , 'collaborators')
    map_attribute_to_json_attribute(:external_funding_source , 'external_funding_source')
    with_association(:budget_division, :lookup_by => :name) do
      map_attribute_to_json_attribute(:name , 'budget_division')
    end
    map_attribute_to_json_attribute(:sequencing_budget_cost_centre , 'budget_cost_centre')
    map_attribute_to_json_attribute(:project_funding_model , 'funding_model')
  end

  extra_json_attributes do |object, json_attributes|
    json_attributes["uuid"] = object.uuid if object.respond_to?(:uuid)

    # Users and roles
    if object.respond_to?(:user)
      json_attributes["user"] = object.user.nil? ? "unknown" : object.user.login
    end
    if object.respond_to?(:roles)
      object.roles.each do |role|
        json_attributes[role.name.underscore] = role.users.map do |user|
          {
            :login => user.login,
            :email => user.email,
            :name  => user.name
          }
        end
      end
    end
  end

end
