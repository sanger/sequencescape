class Io::SampleTube < Io::Tube
  set_model_for_input(::SampleTube)
  set_json_root(:sample_tube)

  define_attribute_and_json_mapping(%Q{})
end
