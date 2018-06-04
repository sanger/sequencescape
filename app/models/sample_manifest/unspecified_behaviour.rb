
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

    def generate
      raise StandardError, 'UnspecifiedBehaviour can not be used to build manifests'
    end
  end

  class RapidCore < Core
  end
end
