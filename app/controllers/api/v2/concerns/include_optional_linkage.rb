# frozen_string_literal: true
module Api
  module V2
    module Concerns
      module IncludeOptionalLinkage
        def relationship_object(source, relationship, rid, include_data)
          include_data ||= relationship.always_include_optional_linkage_data
          if relationship.is_a?(JSONAPI::Relationship::ToOne)
            relationship_object_to_one(source, relationship, rid, include_data)
          elsif relationship.is_a?(JSONAPI::Relationship::ToMany)
            relationship_object_to_many(source, relationship, rid, include_data)
          end
        end
      end
    end
  end
end
