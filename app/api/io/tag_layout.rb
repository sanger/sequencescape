class ::Io::TagLayout < ::Core::Io::Base
  set_model_for_input(::TagLayout)
  set_json_root(:tag_layout)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
        plate <=  plate
    tag_group  => tag_group
  })
end
