@api @json @asset_audit @allow-rescue
Feature: Interacting with asset_audits through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the asset_audits that exist if there aren't any
    When I GET the API path "/asset_audits"
    Then the JSON should be an empty array

  Scenario: Listing all of the asset_audits that exist
    Given the plate exists with ID 1
      And the barcode for plate 1 is "123"
      And the UUID for the plate with ID 1 is "00000000-1111-2222-3333-444444444999"
    Given the asset audit exists with ID 1
      And the UUID for the asset audit with ID 1 is "00000000-1111-2222-3333-444444444444"
      And asset audit with ID 1 is for plate with ID 1

    When I GET the API path "/asset_audits"
    Then ignoring "internal_id" the JSON should be:
      """
      [
      {
        "asset_audit": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "message": "Some message",
          "created_by": "abc123",
          "witnessed_by": "jane",
          "key": "some_key",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",

          "plate_barcode": "123",
          "plate_barcode_prefix": "DN",
          "plate_uuid": "00000000-1111-2222-3333-444444444999",

          "internal_id": 200
        }
      }
      ]
      """

  Scenario: Retrieving the JSON for a asset audit that does not exist
    When I GET the API path "/asset_audits/UUID-xxxxxxx"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular asset_audit
    Given the plate exists with ID 1
      And the barcode for plate 1 is "123"
      And the UUID for the plate with ID 1 is "00000000-1111-2222-3333-444444444999"
    Given the asset audit exists with ID 1
      And the UUID for the asset audit with ID 1 is "00000000-1111-2222-3333-444444444444"
      And asset audit with ID 1 is for plate with ID 1

    When I GET the API path "/asset_audits/00000000-1111-2222-3333-444444444444"
    Then ignoring "internal_id" the JSON should be:
      """
      {
        "asset_audit": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "message": "Some message",
          "created_by": "abc123",
          "key": "some_key",
          "witnessed_by": "jane",

          "plate_barcode": "123",
          "plate_barcode_prefix": "DN",
          "plate_uuid": "00000000-1111-2222-3333-444444444999",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",

          "internal_id": 1
        }
      }
      """
