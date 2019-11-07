# Controls API V1 IO for {::VolumeUpdate}
class ::Io::VolumeUpdate < ::Core::Io::Base
  set_model_for_input(::VolumeUpdate)
  set_json_root(:volume_update)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping("
                       created_by <=> created_by
                    volume_change <=> volume_change
  ")
end
