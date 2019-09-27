# Controls API V1 IO for {::LotType}
class ::Io::LotType < ::Core::Io::Base
  set_model_for_input(::LotType)
  set_json_root(:lot_type)

  define_attribute_and_json_mapping("
                                           name => name
                                 template_class => template_class
                            target_purpose.name => qcable_name
                                   printer_type => printer_type
  ")
end
