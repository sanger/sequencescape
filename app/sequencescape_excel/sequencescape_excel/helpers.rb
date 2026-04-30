# frozen_string_literal: true

module SequencescapeExcel
  ##
  # Helpers
  module Helpers
    def load_file(folder, filename)
      file_path = Rails.root.join(folder, "#{filename}.yml")
      YAML.safe_load_file(file_path, permitted_classes: [Symbol]).with_indifferent_access
    end
  end
end
