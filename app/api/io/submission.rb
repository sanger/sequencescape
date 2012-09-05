class ::Io::Submission < ::Core::Io::Base
  set_model_for_input(::Submission)
  set_json_root(:submission)
  set_eager_loading { |model| model.include_orders }

  define_attribute_and_json_mapping(%Q{
     state  => state
    orders <=> orders
  })
end
