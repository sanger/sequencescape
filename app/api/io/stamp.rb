class Io::Stamp < Core::Io::Base
  set_model_for_input(::Stamp)
  set_json_root(:stamp)

  define_attribute_and_json_mapping(%Q{
          tip_lot <=> tip_lot
             user <=> user
              lot <=> lot
            robot <=> robot

    stamp_details <= stamp_details
  })
end
