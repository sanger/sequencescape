module Billing
  module Factory
    class LibraryCreation < Base
      def project_cost_code
        request.initial_project.project_metadata.project_cost_code || super
      end
    end
  end
end
