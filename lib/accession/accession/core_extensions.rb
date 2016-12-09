module Accession
  ##
  # Core Extensions provide extensions to standard classes
  # which can be included whenever needed.
  module CoreExtensions

    module String
      def sanitize
        self.downcase.gsub(/[^\w\d]/i,'_')
      end
    end
  end
end
