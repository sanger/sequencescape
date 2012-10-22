class ::Io::StateChange < ::Core::Io::Base
  set_model_for_input(::StateChange)
  set_json_root(:state_change)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
              user <=> user
            target <=> target
          contents <=> contents
            reason <=> reason
      target_state <=> target_state
    previous_state  => previous_state
  })
end
