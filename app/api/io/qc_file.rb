# Controls API V1 IO for {::QcFile}
class ::Io::QcFile < ::Core::Io::Base
  set_model_for_input(::QcFile)
  set_json_root(:qc_file)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping("
              filename  => filename
                  size  => size
  ")
end
