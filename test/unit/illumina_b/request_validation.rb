# frozen_string_literal: true

require 'test_helper'
require 'unit/illumina_b/request_statemachine_checks'

class IlluminaB::RequestValidationTest < ActiveSupport::TestCase
  context 'An HTP library creation request' do
    should 'accept the right purpose' do
      plate = Purpose.find_by(name: 'Cherrypicked').create!(barcode: 12_345)
      r =
        RequestType.find_by(name: 'Shared Library Creation').create!(
          asset: plate.wells.first,
          request_metadata_attributes: {
            fragment_size_required_from: 1,
            fragment_size_required_to: 20,
            library_type: 'Standard'
          }
        )

      assert r
    end

    should 'not accept the wrong purpose' do
      assert_raise ActiveRecord::RecordInvalid do
        plate = Purpose.find_by(name: 'ILB_STD_INPUT').create!(barcode: 12_345)
        r =
          RequestType.find_by(name: 'Shared Library Creation').create!(
            asset: plate.wells.first,
            request_metadata_attributes: {
              fragment_size_required_from: 1,
              fragment_size_required_to: 20,
              library_type: 'Standard'
            }
          )

        assert r
      end
    end
  end
end
