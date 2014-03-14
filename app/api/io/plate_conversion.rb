class ::Io::PlateConversion < ::Core::Io::Base
  set_model_for_input(::PlateConversion)
  set_json_root(:plate_conversion)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                 target <=> target
                purpose <=> purpose
  })
end
