# frozen_string_literal: true
# Simple core module to handle options when no type has been specified
# Not valid for actually building manifests, just for rendering forms
module SampleManifest::UnspecifiedBehaviour
  class Core
    def initialize(_manifest)
      # Do nothing
    end

    def acceptable_purposes
      PlatePurpose.for_submissions
    end

    def default_purpose
      PlatePurpose.stock_plate_purpose
    end

    def generate
      raise StandardError, 'UnspecifiedBehaviour can not be used to build manifests'
    end

    def generate_sample_and_aliquot(sanger_sample_id, asset)
      raise StandardError,
            # rubocop:todo Layout/LineLength
            "UnspecifiedBehaviour can not be used to create Sample: #{sanger_sample_id}, for Asset: #{asset.display_name}."
      # rubocop:enable Layout/LineLength
    end
  end
end
