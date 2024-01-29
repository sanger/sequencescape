# frozen_string_literal: true
module Api
    module V2
      module Concerns
        module DefaultIncludesParser
          def parse_include_directives(resource_klass, raw_include)
            if resource_klass.respond_to?(:format_default_includes)
              default_includes = resource_klass.format_default_includes
              raw_include = [raw_include.presence, default_includes.presence].compact.join(',')
            end
            super(resource_klass, raw_include)
          end
        end
      end
    end
end
