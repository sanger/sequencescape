module Api
    module V2
      module Concerns
        module DefaultIncludesParser
          extend ActiveSupport::Concern
          included { prepend_before_action :handle_default_includes }

          def handle_default_includes
            # method body
            # p params
          end
        end
      end
    end
end
