# rake features FEATURE=features/plain/api/sample_tubes.feature
@api @json @sample_tube @allow-rescue
Feature: Interacting with sample tubes through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the sample tubes that exist if there aren't any
    When I GET the API path "/sample_tubes"
    Then the JSON should be an empty array

  Scenario: Listing all of the sample tubes that exist
    Given a sample tube called "Testing the JSON API" exists
    And the UUID for the sample tube "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/sample_tubes"
    Then ignoring "id|barcode|sample_(name|internal_id|uuid)" the JSON should be:
      """
      [
        {
          "sample_tube": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "name": "Testing the JSON API",
            "barcode_prefix": "NT",
            "closed": false,
            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00",
            "concentration": null,
            "scanned_in_date": "",
            "requests": "http://localhost:3000/0_5/sample_tubes/00000000-1111-2222-3333-444444444444/requests",
            "library_tubes": "http://localhost:3000/0_5/sample_tubes/00000000-1111-2222-3333-444444444444/library_tubes",
            "volume": null,
            "qc_state": "",
            "two_dimensional_barcode": null,

            "id": 1,
            "barcode": "1",
            "sample_name": "Sample1",
            "sample_internal_id": 1,
            "sample_uuid": "00000000-1111-2222-3333-444444444445"
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a sample tube that does not exist
    When I GET the API path "/sample_tubes/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular sample tube
    Given a sample tube called "Testing the JSON API" exists
    And the UUID for the sample tube "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/sample_tubes/00000000-1111-2222-3333-444444444444"
    Then ignoring "id|barcode|sample_(name|internal_id|uuid)" the JSON should be:
      """
      {
        "sample_tube": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Testing the JSON API",
          "barcode_prefix": "NT",
          "closed": false,
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",
          "concentration": null,
          "scanned_in_date": "",
          "requests": "http://localhost:3000/0_5/sample_tubes/00000000-1111-2222-3333-444444444444/requests",
          "library_tubes": "http://localhost:3000/0_5/sample_tubes/00000000-1111-2222-3333-444444444444/library_tubes",
          "volume": null,
          "qc_state": "",
          "two_dimensional_barcode": null,

          "barcode": "1",
          "id": 1,
          "sample_name": "Sample1",
          "sample_internal_id": 1,
          "sample_uuid": "00000000-1111-2222-3333-444444444445"
        }
      }
      """

  @asset
  Scenario: Retrieving the children of a sample tube
    Given a sample tube called "Testing the JSON API" exists
    And the UUID for the sample tube "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"

    Given a library tube called "Child for testing the JSON API" exists
    And the library tube "Child for testing the JSON API" is a child of the sample tube "Testing the JSON API"
    And the UUID for the library tube "Child for testing the JSON API" is "ffffffff-1111-2222-3333-444444444444"

    When I GET the API path "/sample_tubes/00000000-1111-2222-3333-444444444444/children"
    Then ignoring "id" the JSON should be:
      """
      [
        {
          "id": 1,
          "name": "Child for testing the JSON API",
          "uuid": "ffffffff-1111-2222-3333-444444444444",
          "url": "http://localhost:3000/0_5/library_tubes/ffffffff-1111-2222-3333-444444444444"
        }
      ]
      """

  Scenario: Retrieving the JSON for the sample tube associated with a sample
    Given the sample named "sample_testing_the_json_api" exists
    And the UUID for the sample "sample_testing_the_json_api" is "ffffffff-1111-2222-3333-444444444444"

    Given a sample tube called "Testing the JSON API" exists
    And the UUID for the sample tube "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And the sample "sample_testing_the_json_api" is in the sample tube "Testing the JSON API"

    When I GET the API path "/samples/ffffffff-1111-2222-3333-444444444444/sample_tubes"
    Then ignoring "id|barcode|sample_internal_id" the JSON should be:
      """
      [
        {
          "sample_tube": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "name": "Testing the JSON API",
            "barcode_prefix": "NT",
            "closed": false,
            "concentration": null,
            "scanned_in_date": "",
            "volume": null,
            "qc_state": "",
            "two_dimensional_barcode": null,
            "sample_uuid": "ffffffff-1111-2222-3333-444444444444",
            "sample_name": "sample_testing_the_json_api",
            "requests": "http://localhost:3000/0_5/sample_tubes/00000000-1111-2222-3333-444444444444/requests",
            "library_tubes": "http://localhost:3000/0_5/sample_tubes/00000000-1111-2222-3333-444444444444/library_tubes",

            "id": 1,
            "barcode": "4",
            "sample_internal_id": 4,
            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00"
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a particular sample tube associated with a sample
    Given the sample named "sample_testing_the_json_api" exists
    And the UUID for the sample "sample_testing_the_json_api" is "ffffffff-1111-2222-3333-444444444444"

    Given a sample tube called "Testing the JSON API" exists
    And the UUID for the sample tube "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And the sample "sample_testing_the_json_api" is in the sample tube "Testing the JSON API"

    When I GET the API path "/samples/ffffffff-1111-2222-3333-444444444444/sample_tubes/00000000-1111-2222-3333-444444444444"
    Then ignoring "id|barcode|sample_internal_id" the JSON should be:
      """
      {
        "sample_tube": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Testing the JSON API",
          "barcode_prefix": "NT",
          "closed": false,
          "concentration": null,
          "scanned_in_date": "",
          "volume": null,
          "qc_state": "",
          "two_dimensional_barcode": null,
          "sample_uuid": "ffffffff-1111-2222-3333-444444444444",
          "sample_name": "sample_testing_the_json_api",
          "requests": "http://localhost:3000/0_5/sample_tubes/00000000-1111-2222-3333-444444444444/requests",
          "library_tubes": "http://localhost:3000/0_5/sample_tubes/00000000-1111-2222-3333-444444444444/library_tubes",

          "id": 1,
          "barcode": "4",
          "sample_internal_id": 4,
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00"
        }
      }
      """

