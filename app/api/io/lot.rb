# Controls API V1 IO for {::Lot}
class ::Io::Lot < ::Core::Io::Base
  set_model_for_input(::Lot)
  set_json_root(:lot)

  set_eager_loading { |model| model.include_lot_type.include_template }

  define_attribute_and_json_mapping("
                                           lot_number <=> lot_number
                                          received_at <=> received_at
                                        template.name  => template_name
                                         lot_type.name => lot_type_name
                                             lot_type <= lot_type
                                                 user <= user
                                             template <= template
  ")
end
