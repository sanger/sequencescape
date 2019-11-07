# Controls API V1 IO for {::LibraryEvent}
class Io::LibraryEvent < ::Core::Io::Base
  set_model_for_input(::LibraryEvent)
  set_json_root(:library_event)

  define_attribute_and_json_mapping("
              event_type <=> event_type
                    user <=> user
                    seed <=> seed
  ")
end
