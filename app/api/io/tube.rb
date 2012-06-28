class Io::Tube < Io::Asset
  set_model_for_input(::Tube)
  set_json_root(:tube)
  set_eager_loading { |model| model.include_aliquots.include_scanned_into_lab_event }

  define_attribute_and_json_mapping(%Q{
             closed  => closed
      concentration  => concentration
             volume  => volume
    scanned_in_date  => scanned_in_date

           aliquots  => aliquots
  })
end
