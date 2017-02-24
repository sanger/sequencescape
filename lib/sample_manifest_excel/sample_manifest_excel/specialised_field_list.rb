module SampleManifestExcel
  class SpecialisedFieldList
    include List

    list_for :specialised_fields, keys: [:type]
  end
end
