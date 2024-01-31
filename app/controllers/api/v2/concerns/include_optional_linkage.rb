# frozen_string_literal: true
module Api
  module V2
    module Concerns
      module IncludeOptionalLinkage
        def relationship_object(source, relationship, rid, include_data)
          hash = include_directives.include_directives
          include_data ||= relationship_exists?(relationship.name.to_sym, hash)
          include_data ||= relationship.always_include_optional_linkage_data
          if relationship.is_a?(JSONAPI::Relationship::ToOne)
            relationship_object_to_one(source, relationship, rid, include_data)
          elsif relationship.is_a?(JSONAPI::Relationship::ToMany)
            relationship_object_to_many(source, relationship, rid, include_data)
          end
        end

        # https://jsonapi.org/format/#document-resource-object-linkage
        def relationship_exists?(name, hash)
          return false unless hash
          hash.each do |key, value|
            if key == :include_related && value.is_a?(Hash) && value.key?(name)
              return true
            end
            if value.is_a?(Hash)
              result = relationship_exists?(name, value)
              return true if result
            end
          end
          false
        end
      end
    end
  end
end
