# frozen_string_literal: true

# Generates a warehouse message describing a {QcResult}
class Api::Messages::QcResultIO < Api::Base
  module Extensions
    def assay
      "#{assay_type} #{assay_version}"
    end
  end

  module AliquotExtensions
    def library_identifier
      library&.external_identifier
    end
  end

  module AssetExtensions
    def labware_purpose
    end
  end

  module WellExtensions
    def labware_purpose
      plate&.purpose&.name
    end
  end

  module TubeExtensions
    def labware_purpose
      purpose&.name
    end
  end

  renders_model(::QcResult)

  map_attribute_to_json_attribute(:id, 'id_qc_result_lims')
  map_attribute_to_json_attribute(:assay)
  map_attribute_to_json_attribute(:value)
  map_attribute_to_json_attribute(:units)
  map_attribute_to_json_attribute(:cv)
  map_attribute_to_json_attribute(:key, 'qc_type')
  map_attribute_to_json_attribute(:created_at, 'date_created')
  map_attribute_to_json_attribute(:updated_at, 'last_updated')

  with_association(:asset) do
    map_attribute_to_json_attribute(:labware_purpose)
    map_attribute_to_json_attribute(:external_identifier, 'id_pool_lims')
    with_nested_has_many_association(:aliquots) do
      map_attribute_to_json_attribute(:library_identifier, 'id_library_lims')
      with_association(:sample) { map_attribute_to_json_attribute(:uuid, 'sample_uuid') }
    end
  end
end
