# rake features FEATURE=features/plain/api/wells.feature
@api @json @well @asset @allow-rescue @well_api
Feature: Interacting with wells through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the wells that exist if there aren't any
    When I GET the API path "/wells"
    Then the JSON should be an empty array

  Scenario: Listing all of the wells that exist
    Given a well called "Testing the JSON API" exists
    And the UUID for the well "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And well "Testing the JSON API" has a genotyping status of "Imported to Illumina: 123456 | Imported to Illumina: 987654"

    When I GET the API path "/wells"
    Then ignoring "internal_id|sample_uuid" the JSON should be:
      """
      [
        {
          "well": {
            "name": "Testing the JSON API",
            "display_name": "Testing the JSON API",
            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00",
            "uuid": "00000000-1111-2222-3333-444444444444",
            "lanes": "http://localhost:3000/0_5/wells/00000000-1111-2222-3333-444444444444/lanes",
            "requests": "http://localhost:3000/0_5/wells/00000000-1111-2222-3333-444444444444/requests",
            "pico_pass": "ungraded",
            "concentration": 23.2,
            "current_volume": 15.0,
            "measured_volume": null,
            "sequenom_count": null,
            "gender_markers": null,
            "genotyping_status": "Imported to Illumina: 123456 | Imported to Illumina: 987654",
            "genotyping_snp_plate_id": 123456,
            "sample_name": "Testing_the_JSON_API",

            "internal_id": 1
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a well that does not exist
    When I GET the API path "/wells/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular well
    Given a well called "Testing the JSON API" exists
    And the UUID for the well "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    Given a plate called "Testing the JSON API" exists
    And the UUID for the plate "Testing the JSON API" is "UUID-1234567890"
    And well "00000000-1111-2222-3333-444444444444" is holded by plate "UUID-1234567890"

    When I GET the API path "/wells/00000000-1111-2222-3333-444444444444"
    Then ignoring "internal_id|plate_barcode" the JSON should be:
      """
      {
        "well": {
          "name": "Testing the JSON API",
          "display_name": "Testing the JSON API",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",
          "uuid": "00000000-1111-2222-3333-444444444444",
          "lanes": "http://localhost:3000/0_5/wells/00000000-1111-2222-3333-444444444444/lanes",
          "requests": "http://localhost:3000/0_5/wells/00000000-1111-2222-3333-444444444444/requests",
          "pico_pass": "ungraded",
          "concentration": 23.2,
          "current_volume": 15.0,
          "measured_volume": null,
          "sequenom_count": null,
          "gender_markers": null,

          "plate_uuid": "UUID-1234567890",
          "plate_barcode_prefix": "DN",

          "plate_barcode": "2",
          "internal_id": 1
        }
      }
      """

  Scenario: Retrieving the children of a well
    Given a well called "Testing the JSON API" exists
    And the UUID for the well "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"

    Given a well called "Child well for the JSON API" exists
    And the well "Child well for the JSON API" is a child of the well "Testing the JSON API"
    And the UUID for the well "Child well for the JSON API" is "ffffffff-1111-2222-3333-444444444444"

    When I GET the API path "/wells/00000000-1111-2222-3333-444444444444/children"
    Then ignoring "id" the JSON should be:
      """
      [
        {
          "id": 1,
          "name": "Child well for the JSON API",
          "uuid": "ffffffff-1111-2222-3333-444444444444",
          "url": "http://localhost:3000/0_5/wells/ffffffff-1111-2222-3333-444444444444"
        }
      ]
      """

  Scenario: Retrieving the parents of a well
    Given a well called "Testing the JSON API" exists
    And the UUID for the well "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"

    Given a well called "Parent well for the JSON API" exists
    And the well "Testing the JSON API" is a child of the well "Parent well for the JSON API"
    And the UUID for the well "Parent well for the JSON API" is "ffffffff-1111-2222-3333-444444444444"

    When I GET the API path "/wells/00000000-1111-2222-3333-444444444444/parents"
    Then ignoring "id" the JSON should be:
      """
      [
        {
          "id": 1,
          "name": "Parent well for the JSON API",
          "uuid": "ffffffff-1111-2222-3333-444444444444",
          "url": "http://localhost:3000/0_5/wells/ffffffff-1111-2222-3333-444444444444"
        }
      ]
      """

  Scenario: Convenient well naming format is exposed in the warehouse
     Given the nameless well exists with ID 1
      And the UUID for the well with ID 1 is "00000000-1111-2222-3333-444444444444"
      Given the plate exists with ID 2
      And the plate with ID 2 has a barcode of "1220123456808"
      And the UUID for the plate with ID 2 is "UUID-1234567890"
      Given the well with ID 1 is at position "B1" on the plate with ID 2
      When I GET the API path "/wells/00000000-1111-2222-3333-444444444444"
      Then ignoring "internal_id" the JSON should be:
        """
        {
          "well": {
            "display_name": "DN123456P:B1",
            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00",
            "uuid": "00000000-1111-2222-3333-444444444444",
            "lanes": "http://localhost:3000/0_5/wells/00000000-1111-2222-3333-444444444444/lanes",
            "requests": "http://localhost:3000/0_5/wells/00000000-1111-2222-3333-444444444444/requests",
            "pico_pass": "ungraded",
            "concentration": 23.2,
            "current_volume": 15.0,
            "measured_volume": null,
            "sequenom_count": null,
            "gender_markers": null,
            "map":"B1",

            "plate_uuid": "UUID-1234567890",
            "plate_barcode_prefix": "DN",

            "plate_barcode": "123456",
            "internal_id": 1
          }
        }
        """


