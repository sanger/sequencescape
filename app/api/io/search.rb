class ::Io::Search < ::Core::Io::Base
  set_json_root(:search)

  define_attribute_and_json_mapping(%Q{
    name  => name
  })
end
