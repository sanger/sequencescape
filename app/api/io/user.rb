class ::Io::User < ::Core::Io::Base
  set_model_for_input(::User)
  set_json_root(:user)
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
