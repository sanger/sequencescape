module Accession
  ##
  # Core Extensions provide extensions to standard classes
  # which can be included whenever needed.
  module CoreExtensions
    module String
      # replace everything that is not a valid character with an underscore
      def sanitize
        downcase.gsub(/[^\w\d]/i, '_')
      end
    end
  end
end
