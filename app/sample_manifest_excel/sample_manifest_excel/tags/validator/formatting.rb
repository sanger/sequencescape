# frozen_string_literal: true

module SampleManifestExcel
  module Tags
    module Validator
      ##
      # Formatting
      module Formatting
        extend ActiveSupport::Concern

        included { validate :check_formatting }

        def check_formatting
          return if value.blank?

          errors.add(:tag, 'must be a combination of A,C,G,T or N') unless value.match?(/\A[acgtnACGTN]+\z/)
        end
      end
    end
  end
end
