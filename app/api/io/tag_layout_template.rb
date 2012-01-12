class ::Io::TagLayoutTemplate < ::Core::Io::Base
  set_model_for_input(::TagLayoutTemplate)
  set_json_root(:tag_layout_template)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
                 name  => name
            tag_group  => tag_group
            direction  => direction
           walking_by  => walking_by
  })
end
