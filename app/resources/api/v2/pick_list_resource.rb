# frozen_string_literal: true

module Api
  module V2
    # Provides a JSON API representation of PickList
    # See: http://jsonapi-resources.com/ for JSONAPI::Resource documentation
    class PickListResource < BaseResource
      # The record cache collects all ids used in the request and optimizes
      # the lookup into a single query, with appropriate eager loading.
      class RecordCache
        def initialize
          @receptacle_ids = []
          @study_ids = []
          @project_ids = []
        end

        def <<(entry)
          source_receptacle_id, study_id, project_id = entry.values_at(:source_receptacle_id, :study_id, :project_id)
          @receptacle_ids << source_receptacle_id if source_receptacle_id
          @study_ids << study_id if study_id
          @project_ids << project_id if project_id
          self
        end

        def convert(entry)
          source_receptacle_id, study_id, project_id = entry.values_at(:source_receptacle_id, :study_id, :project_id)
          entry.permit(*PERMITTED_PICK_ATTRIBUTES)
               .to_hash
               .tap do |converted|
            converted[:source_receptacle] = source_receptacle(source_receptacle_id) if source_receptacle_id
            converted[:study] = study(study_id) if study_id
            converted[:project] = project(project_id) if project_id
          end
        end

        private

        def source_receptacle(id)
          @source_receptacle ||= Receptacle.includes(:studies, :projects)
                                           .find(@receptacle_ids)
                                           .index_by(&:id)
          @source_receptacle.fetch(id)
        end

        def study(id)
          @study ||= Study.find(@study_ids).index_by(&:id)
          @study.fetch(id)
        end

        def project(id)
          @project ||= Project.find(@project_ids).index_by(&:id)
          @project.fetch(id)
        end
      end
      # Constants...

      # immutable # uncomment to make the resource immutable

      # model_name / model_hint if required

      # Associations

      # Attributes
      attribute :created_at, readonly: true
      attribute :updated_at, readonly: true
      attribute :state, readonly: true
      attribute :links, readonly: true

      attribute :pick_attributes
      attribute :asynchronous

      # Any permitted pick attributes beyond the relationships handled in the cache
      PERMITTED_PICK_ATTRIBUTES = [].freeze

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
        # Extract and look up records here
        # before passing through
        cache = picks.reduce(RecordCache.new) { |building_cache, pick| building_cache << pick }
        @model.pick_attributes = picks.map { |pick| cache.convert(pick) }
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
