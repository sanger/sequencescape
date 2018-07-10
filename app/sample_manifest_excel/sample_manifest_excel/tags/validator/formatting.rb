# frozen_string_literal: true

module SampleManifestExcel
  module Tags
    module Validator
      ##
      # Formatting
      module Formatting
        extend ActiveSupport::Concern

        included do
          validate :check_formatting
        end

        def check_formatting
          return if value.blank?
          errors.add(:tag, 'must be a combination of A,C,G and T') unless value.match?(/\A[acgtACGT]+\z/)
        end
      end
    end
  end
end
