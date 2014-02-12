class ::Io::Lot < ::Core::Io::Base
  set_model_for_input(::Lot)
  set_json_root(:lot)

  define_attribute_and_json_mapping(%Q{
                                           lot_number <=> lot_number
                                          recieved_at <=> recieved_at
                                        template.name  => template_name
                                         lot_type.name => lot_type_name
                                             lot_type <= lot_type
                                             user <= user
                                             template <= template
  })
end
