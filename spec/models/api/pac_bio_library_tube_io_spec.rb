# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Api::PacBioLibraryTubeIO do
  subject do
    create :pac_bio_library_tube,
           :scanned_into_lab,
           concentration: 8.0,
           volume: 12.0,
           pac_bio_library_tube_metadata_attributes: {
             prep_kit_barcode: 999,
             binding_kit_barcode: 233,
             smrt_cells_available: 5,
             movie_length: 100,
             protocol: 'xyzzy'
           }
  end

  let(:expected_json) do
    {
      'uuid' => subject.uuid,
      'internal_id' => subject.id,
      'name' => subject.name,
      'barcode' => subject.barcode_number,
      'barcode_prefix' => 'NT',
      'public_name' => subject.public_name,
      'qc_state' => subject.qc_state,
      'closed' => false,
      'volume' => 12.0,
      'concentration' => 8.0,
      'scanned_in_date' => subject.scanned_in_date,
      'prep_kit_barcode' => '999',
      'binding_kit_barcode' => '233',
      'smrt_cells_available' => 5,
      'movie_length' => '100',
      'protocol' => 'xyzzy'
    }
  end

  it_behaves_like('an IO object')
end
