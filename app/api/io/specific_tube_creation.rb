# Controls API V1 IO for {::SpecificTubeCreation}
class ::Io::SpecificTubeCreation < ::Core::Io::Base
  set_model_for_input(::SpecificTubeCreation)
  set_json_root(:specific_tube_creation)
  set_eager_loading(&:include_parent)

  define_attribute_and_json_mapping('
     user <=> user
     parent <=> parent
     set_child_purposes <=  child_purposes
     tube_attributes <= tube_attributes
  ')
end
