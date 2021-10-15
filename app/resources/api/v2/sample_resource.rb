# frozen_string_literal: true

module Api
  module V2
    # SampleResource
    class SampleResource < BaseResource
      default_includes :uuid_object

      has_one :sample_metadata, class_name: 'SampleMetadata', foreign_key_on: :related

      has_many :component_samples
      has_many :sample_compound_components

      attribute :name
      attribute :sanger_sample_id
      attribute :uuid
      attribute :control
      attribute :control_type
      attribute :sample_compound_component_data

      filter :uuid
      filter :sanger_sample_id
      filter :name

      def sample_compound_component_data=(linking_data)
        ActiveRecord::Base.transaction do
          linking_data.each do |data|
            SampleCompoundComponent
              .where(compound_sample_id: id, component_sample_id: data[:sample_id])
              .each do |sample_compound_component|
                sample_compound_component.update(asset_id: data[:asset_id], target_asset_id: data[:target_asset_id])

                _pass_sample_compound_request_for_well(data)
              end
          end
        end
      end

      def _pass_sample_compound_request_for_well(data)
        well = Well.find(data[:asset_id])
        return unless well
        req = well.outer_requests.first
        return unless req&.request_type&.key == 'limber_cardinal_sample_compound'
        req.update(target_asset_id: data[:target_asset_id])
        req.pass!
      end

      def sample_compound_component_data
        nil
      end
    end
  end
end
