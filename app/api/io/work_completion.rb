# Controls API V1 IO for {::WorkCompletion}
class ::Io::WorkCompletion < ::Core::Io::Base
  set_model_for_input(::WorkCompletion)
  set_json_root(:work_completion)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping("
    user <= user
    target <= target
    submissions <= submissions
  ")
end
