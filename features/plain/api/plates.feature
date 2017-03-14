# rake features FEATURE=features/plain/api/plates.feature
@api @json @plate @asset @allow-rescue @plate_api
Feature: Interacting with plates through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the plates that exist if there aren't any
    When I GET the API path "/plates"
    Then the JSON should be an empty array

  Scenario: Listing all of the plates that exist
    Given a plate called "Testing the JSON API" exists with purpose "Stock Plate"
    And the UUID for the plate "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And the infinium barcode for plate "Testing the JSON API" is "WG123456"

    When I GET the API path "/plates"
    Then ignoring "updated_at|id|barcode|plate_purpose_uuid|plate_purpose_internal_id" the JSON should be:
      """
      [
        {
          "plate": {
            "name": "Testing the JSON API",
            "size": 96,
            "barcode_prefix": "DN",
            "plate_purpose_name": "Stock Plate",
            "infinium_barcode": "WG123456",
            "location": "Sample logistics freezer",

            "created_at": "2010-09-16T13:45:00+01:00",
            "uuid": "00000000-1111-2222-3333-444444444444",
            "barcode": "2",
            "plate_purpose_uuid": "34567",
            "plate_purpose_internal_id": "2",
            "id": 1
          }, "lims": "SQSCP"
        }
      ]
      """

  Scenario: Retrieving the JSON for a plate that does not exist
    When I GET the API path "/plates/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular plate
    Given a plate called "Testing the JSON API" exists with purpose "Stock Plate"
    And the UUID for the plate "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And the infinium barcode for plate "Testing the JSON API" is "WG123456"

    When I GET the API path "/plates/00000000-1111-2222-3333-444444444444"
    Then ignoring "updated_at|id|barcode|plate_purpose_uuid|plate_purpose_internal_id" the JSON should be:
      """
      {
        "plate": {
          "name": "Testing the JSON API",
          "size": 96,
          "barcode_prefix": "DN",
          "plate_purpose_name": "Stock Plate",
          "infinium_barcode": "WG123456",
          "location": "Sample logistics freezer",

          "created_at": "2010-09-16T13:45:00+01:00",
          "uuid": "00000000-1111-2222-3333-444444444444",
          "barcode": "2",
          "plate_purpose_uuid": "34567",
          "plate_purpose_internal_id": "2",
          "id": 1
        }, "lims": "SQSCP"
      }
      """
