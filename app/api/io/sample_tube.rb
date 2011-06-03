class Io::SampleTube < Io::Asset
  set_model_for_input(::SampleTube)
  set_json_root(:sample_tube)
  set_eager_loading { |model| model.include_aliquots.include_scanned_into_lab_event }

  define_attribute_and_json_mapping(%Q{
                       closed  => closed
                concentration  => concentration
                       volume  => volume
              scanned_in_date  => scanned_in_date
                     aliquots  => aliquots
  })
end
