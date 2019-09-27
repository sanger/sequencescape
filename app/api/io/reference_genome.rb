# Controls API V1 IO for {::ReferenceGenome}
class ::Io::ReferenceGenome < ::Core::Io::Base
  set_model_for_input(::ReferenceGenome)
  set_json_root(:reference_genome)

  define_attribute_and_json_mapping("
    name  <=> name
  ")
end
