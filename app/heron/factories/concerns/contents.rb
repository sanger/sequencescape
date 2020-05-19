# frozen_string_literal: true

module Heron
  module Factories
    # Factory class to create Heron tube racks
    module Concerns
      #
      # A foreign barcode is a barcode that has been externally set, that is added as
      # another extra barcode for the labware referred.
      # This module adds validation and processing methods for this barcodes
      module Contents
        def self.included(klass)
          klass.instance_eval do
            validate :contents
          end
        end

        def study_uuid
          @params[:study_uuid]
        end

        def contents
          #unless @params[recipients_key]
          #  errors.add(:recipients, "Recipient key not found ")
          #end
          return if errors.count.positive?

          #@contents ||= ::Heron::Factories::Contents.new(params_for_contents, @params[:study_uuid])
          return unless params_for_contents
          @contents ||= params_for_contents.keys.each_with_object({}) do |coordinate, memo|
            samples_params = [params_for_contents[coordinate]].flatten.compact
            memo[unpad_coordinate(coordinate)]=_factories_for_location(coordinate, samples_params)
          end
        end

        def add_aliquots_into_locations(containers_for_locations)
          return unless contents
          contents.each do |location, factories|
            container = containers_for_locations[location]
            factories.each do |factory|
              factory.create_aliquot_at(container) if factory.valid?
            end
          end
          true
        end 

        def params_for_contents
          return unless @params[recipients_key]

          @params_for_contents ||= @params[recipients_key].keys.each_with_object({}) do |location, obj|
            obj[unpad_coordinate(location)] = @params.dig(recipients_key, location, :content)
          end
        end

        def _factories_for_location(location, samples_params)
          samples_params.each_with_index.map do |sample_params, pos|
            label = samples_params.length == 1 ? "Content #{location}" : "Content #{location}, pos: #{pos}"
            sample_params = sample_params.merge(study_uuid: study_uuid) if study_uuid
            factory = content_factory.new(sample_params)
            errors.add(label, factory.errors.full_messages) unless factory.valid?
            factory
          end
        end
  
      end
    end
  end
end
