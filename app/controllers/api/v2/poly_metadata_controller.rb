# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API controller for PolyMetadatum
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PolyMetadataController < JSONAPI::ResourceController
      # By default JSONAPI::ResourceController provides most the standard
      # behaviour, and in many cases this file may be left empty.
      def bulk_create
        created = []
        PolyMetadatum.transaction do
          params[:data].each do |poly|
            attrs        = poly[:attributes]
            relationship = poly[:relationships][:metadatable][:data]

            created << PolyMetadatum.create!(
              key: attrs[:key],
              value: attrs[:value],
              metadatable_type: relationship[:type].classify,
              metadatable_id: relationship[:id]
            )
          end
        end

        render json: { data: created.map { |p| serialize_poly_metadatum(p) } }, status: :created
      end


      private

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
              data: { type: poly.metadatable_type.underscore, id: poly.metadatable_id.to_s }
            }
          }
        }
      end
    end
  end
end
