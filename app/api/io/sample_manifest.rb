class ::Io::SampleManifest < ::Core::Io::Base
  # This module adds the behaviour we require from the SampleManifest module.
  module ApiIoSupport
    def self.included(base)
      base.class_eval do
        # TODO: add any named scopes
        # TODO: add any associations
      end
    end

    def barcodes_array
      self.barcodes || []
    end
  end

  set_json_root(:sample_manifest)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need
  
  define_attribute_and_json_mapping(%Q{
       last_errors  => last_errors
             state  => state
    barcodes_array  => barcodes
  })
end
