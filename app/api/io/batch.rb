class ::Io::Batch < ::Core::Io::Base
  set_model_for_input(::Batch)
  set_json_root(:batch)
  set_eager_loading { |model| model.include_user.include_requests.include_pipeline }

  define_attribute_and_json_mapping(%Q{
               state  => state
    production_state  => production_state
            qc_state  => qc_state
             barcode  => barcode
          user.login  => user.login

            requests <=> requests
  })
end
