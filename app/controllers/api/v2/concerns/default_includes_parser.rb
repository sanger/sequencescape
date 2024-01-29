module Api
    module V2
      module Concerns
        module DefaultIncludesParser
          def parse_include_directives(resource_klass, raw_include)
            if resource_klass.respond_to?(:format_default_includes)
              p 'X' * 80
              p resource_klass.format_default_includes
              p 'Y' * 80
            end
            super
          end
        end
      end
    end
end
