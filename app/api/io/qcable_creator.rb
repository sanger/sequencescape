# frozen_string_literal: true
# Controls API V1 IO for QcableCreator
class Io::QcableCreator < Core::Io::Base
  set_model_for_input(::QcableCreator)
  set_json_root(:qcable_creator)

  define_attribute_and_json_mapping(
    '
                user <=> user
                 lot <=> lot
               count <= count
               barcodes <= barcodes

  '
  )
end
