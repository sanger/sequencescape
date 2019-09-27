# Controls API V1 IO for {::SampleManifest}
class ::Io::SampleManifest < ::Core::Io::Base
  set_model_for_input(::SampleManifest)
  set_json_root(:sample_manifest)
  set_eager_loading(&:include_samples)

  define_attribute_and_json_mapping("
                   last_errors  => last_errors
                         state  => state
                    io_samples  => samples
  ")
end
