class ::Io::User < ::Core::Io::Base
  set_model_for_input(::User)
  set_json_root(:user)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need
  
  # TODO: define the mapping from the model attributes to the JSON attributes
  #
  # The rules are relatively straight forward with each line looking like '<attibute> <access> <json>', and blank lines or
  # those starting with '#' being considered comments and ignored.
  #
  # Here 'access' is either '=>' (for read only, indicating that the 'attribute' maps to the 'json'), or '<=' for write only (yes,
  # there are cases for this!) or '<=>' for read-write.
  #
  # The 'json' is the JSON attribute to generate in dot notation, i.e. 'parent.child' generates the JSON '{parent:{child:value}}'.
  #
  # The 'attribute' is the attribute to write, i.e. 'name' would be the 'name' attribute, and 'parent.name' would be the 'name'
  # attribute of whatever 'parent' is.
  define_attribute_and_json_mapping(%Q{
                        login  => login
                        email <=> email
                   first_name <=> first_name
                    last_name <=> last_name
                      barcode <=> barcode
                swipecard_code <=  swipecard_code
               swipecard_code?  => has_a_swipecard_code

})
end
