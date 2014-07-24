class Io::QcableCreator < Core::Io::Base
  set_model_for_input(::QcableCreator)
  set_json_root(:qcable_creator)

  define_attribute_and_json_mapping(%Q{
                user <=> user
                 lot <=> lot
               count <= count

  })
end
