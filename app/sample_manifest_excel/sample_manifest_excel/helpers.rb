module SampleManifestExcel
  module Helpers
    def load_file(folder, filename)
      YAML::load_file(File.join(Rails.root, folder, "#{filename}.yml")).with_indifferent_access
    end
  end
end
