# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of submission
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class SubmissionTemplateResource < BaseResource
      # Constants...

      #immutable # comment to make the resource mutable
      attributes :name, :uuid, :orders_attributes
      

      # model_name / model_hint if required

      #default_includes :uuid_object, :sequencing_requests

      # Associations:
      has_many :orders

      # Attributes

      # Filters
      filter :uuid, apply: ->(records, value, _options) { records.with_uuid(value) }

      # Custom methods

      def orders_attributes
        @created_orders_uuids
      end

      def orders_attributes=(orders)
        orders.map(&:permit!)
        @created_orders_uuids = orders.map do |order|
          order['user'] = User.with_uuid(order['user']).first
          order['assets'] = Receptacle.with_uuid(order['assets'])
          created_order = _model.create_order!(order)
          created_order.uuid
        end
      end

      # Class method overrides
    end
  end
end
