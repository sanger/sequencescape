class ::Io::LotType < ::Core::Io::Base
  set_model_for_input(::LotType)
  set_json_root(:lot_type)

  define_attribute_and_json_mapping(%Q{
                                           name => name
                                 template_class => template_class
  })
end
