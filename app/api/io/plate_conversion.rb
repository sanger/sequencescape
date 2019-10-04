# Controls API V1 IO for {::PlateConversion}
class ::Io::PlateConversion < ::Core::Io::Base
  set_model_for_input(::PlateConversion)
  set_json_root(:plate_conversion)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping("
                   user <=> user
                 target <=> target
                purpose <=> purpose
                 parent <=  parent
  ")
end
