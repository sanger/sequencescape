# frozen_string_literal: true

module SequencescapeExcel
  ##
  # Helpers
  module Helpers
    include RetentionInstructionHelper
    def load_file(folder, filename)
      YAML.load_file(Rails.root.join(folder, "#{filename}.yml")).with_indifferent_access
    end
  end
end
