# frozen_string_literal: true
module Api
  module V2
    module Concerns
      module NestedIncludeExpander
        def parse_include_directives(resource_klass, raw_include)
          raw_include ||= ''
          raw_include = expand_include_parameters(raw_include)
          super(resource_klass, raw_include)
        end

        def expand_include_parameters(raw_include)
          raw_include.split(',').flat_map do |path|
            path.split('.').each_with_index.map { |_, index| path.split('.')[0..index].join('.') }
          end.uniq.join(',')
        end
      end
    end
  end
end
