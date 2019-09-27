# Controls API V1 IO for {::TubeCreation}
class ::Io::TubeCreation < ::Core::Io::Base
  set_model_for_input(::TubeCreation)
  set_json_root(:tube_creation)
  set_eager_loading(&:include_parent)

  define_attribute_and_json_mapping("
                   user <=> user
                 parent <=> parent
          child_purpose <=> child_purpose
  ")
end
