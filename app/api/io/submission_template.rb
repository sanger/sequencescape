class ::Io::SubmissionTemplate < ::Core::Io::Base
  set_model_for_input(::SubmissionTemplate)
  set_json_root(:order_template)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
           name => name
  })
end
