# Controls API V1 IO for {::Submission}
class ::Io::Submission < ::Core::Io::Base
  set_model_for_input(::Submission)
  set_json_root(:submission)
  set_eager_loading(&:include_orders)

  define_attribute_and_json_mapping("
     state  => state
    orders <=> orders

      user <=  user
  ")
end
