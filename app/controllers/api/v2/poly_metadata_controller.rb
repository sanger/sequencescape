# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for PolyMetadatum
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PolyMetadataController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
      def bulk_create
        created = PolyMetadatum.transaction do
          params[:data].map { |poly| build_poly_metadatum(poly) }
        end

        render json: { data: created.map { |p| serialize_poly_metadatum(p) } },
               status: :created
      rescue StandardError => e
        render json: { error: "PolyMetadatum bulk creation failed: #{e.message}" }, status: :internal_server_error
      end

      private

      def build_poly_metadatum(poly)
        attrs        = poly[:attributes]
        relationship = poly[:relationships][:metadatable][:data]

        PolyMetadatum.create!(
          key: attrs[:key],
          value: attrs[:value],
          metadatable_type: relationship[:type].classify,
          metadatable_id: relationship[:id]
        )
      end

      def serialize_poly_metadatum(poly)
        {
          id: poly.id.to_s,
          type: 'poly_metadata',
          attributes: {
            key: poly.key,
            value: poly.value
          },
          relationships: {
            metadatable: {
              data: { type: poly.metadatable_type.underscore.pluralize, id: poly.metadatable_id.to_s }
            }
          }
        }
      end
    end
  end
end
