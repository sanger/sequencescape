# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of PickList
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PickListResource < BaseResource
      # Constants...
      PERMITTED_PICK_ATTRIBUTES = %i[source_receptacle_id study_id project_id].freeze
      PERMITTED_LABWARE_PICK_ATTRIBUTES = %i[source_labware_id source_labware_barcode study_id project_id].freeze
      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      # Associations

      # Attributes
      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true
      attribute :state, readonly: true
      attribute :links, readonly: true

      attribute :pick_attributes
      attribute :labware_pick_attributes, writeonly: true
      attribute :asynchronous

      # Filters

      # Custom methods
      # These shouldn't be used for business logic, and a more about
      # I/O and isolating implementation details.

      # JSON API v1.0 doesn't have native support for creating nested resources
      # in a single request. In addition, as {PickList::Pick picks} are not backed
      # by real database records yet we could expect to run into issues anyway.
      # So we just expose our pick attributes. However, as we can't expect to
      # receive actual receptacles/studies/projects over the API, we convert them
      # from the ids. The RecordCache allows us to do this with a single database
      # query.
      def pick_attributes=(picks)
        # Extract and look up records here before passing through
        cache = PickList::RecordCache::ByReceptacle.new(picks)
        @model.pick_attributes = picks.map { |pick| cache.convert(pick.permit(PERMITTED_PICK_ATTRIBUTES)) }
      rescue KeyError => e
        # We'll see this if one of the attributes passed in doesn't match an actual record,
        # such as a non-existent study id.
        raise JSONAPI::Exceptions::BadRequest, e.message
      end

      # This provides an alternative API for passing in a list of labware, either by
      # ids or barcodes. This avoids the need to make additional requests for the receptacle
      # ids. We keep this as a separate accessor to avoid the confusion of passing in a list
      # of 12 picks, and receiving more back.
      def labware_pick_attributes=(labware_picks)
        # Extract and look up records here before passing through
        cache = PickList::RecordCache::ByLabware.new(labware_picks)
        @model.pick_attributes = labware_picks.flat_map do |pick|
          cache.convert(pick.permit(PERMITTED_LABWARE_PICK_ATTRIBUTES))
        end
      rescue KeyError => e
        # We'll see this if one of the attributes passed in doesn't match an actual record,
        # such as a non-existent study id.
        raise JSONAPI::Exceptions::BadRequest, e.message
      end

      def pick_attributes
        @model.pick_attributes.map do |pick|
          {
            source_receptacle_id: pick[:source_receptacle].id,
            study_id: pick[:study]&.id,
            project_id: pick[:project]&.id
          }
        end
      end

      # Class method overrides
    end
  end
end
