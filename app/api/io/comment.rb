# Controls API V1 IO for {::Comment}
class Io::Comment < ::Core::Io::Base
  set_model_for_input(::Comment)
  set_json_root(:comment)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping("
                                           user  <=  user
                                          title  <=> title
                                    description  <=> description
  ")
end
