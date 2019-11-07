# Controls API V1 IO for {::TubeFromTubeCreation}
class ::Io::TubeFromTubeCreation < ::Core::Io::Base
  set_model_for_input(::TubeFromTubeCreation)
  set_json_root(:tube_from_tube_creation)

  set_eager_loading { |model| model.includes(parent: { aliquots: Io::Aliquot::PRELOADS }) }

  define_attribute_and_json_mapping("
                   user <=> user
                 parent <=> parent
          child_purpose <=> child_purpose
  ")
end
