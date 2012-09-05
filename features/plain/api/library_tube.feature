@api @json @library_tube @asset @allow-rescue @library_tube_api
Feature: Interacting with library_tubes through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the library_tubes that exist if there aren't any
    When I GET the API path "/library_tubes"
    Then the JSON should be an empty array

  Scenario: Listing all of the library_tubes that exist
    Given a library tube called "Testing the JSON API" exists
    And the UUID for the library tube "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And tube "Testing the JSON API" has a public name of "ABC"

    When I GET the API path "/library_tubes"
    Then ignoring "id|sample_name" the JSON should be:
      """
      [
        {
          "library_tube": {
            "name": "Testing the JSON API",
            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00",
            "uuid": "00000000-1111-2222-3333-444444444444",
            "barcode_prefix": "NT",
            "scanned_in_date": "",
            "public_name": "ABC",
            "lanes": "http://localhost:3000/0_5/library_tubes/00000000-1111-2222-3333-444444444444/lanes",
            "requests": "http://localhost:3000/0_5/library_tubes/00000000-1111-2222-3333-444444444444/requests",
            "qc_state": "",

            "id": 1
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a library_tube that does not exist
    When I GET the API path "/library_tubes/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular library_tube
    Given a library tube called "Testing the JSON API" exists
    And the UUID for the library tube "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    When I GET the API path "/library_tubes/00000000-1111-2222-3333-444444444444"
    Then ignoring "id|sample_name" the JSON should be:
      """
      {
        "library_tube": {
          "name": "Testing the JSON API",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",
          "uuid": "00000000-1111-2222-3333-444444444444",
          "barcode_prefix": "NT",
          "scanned_in_date": "",
          "lanes": "http://localhost:3000/0_5/library_tubes/00000000-1111-2222-3333-444444444444/lanes",
          "requests": "http://localhost:3000/0_5/library_tubes/00000000-1111-2222-3333-444444444444/requests",
          "qc_state": "",

          "id": 1
        }
      }
      """

  Scenario: When the contents, rather than the tube, have been modified the timestamps should be more current
    Given a library tube called "Testing the JSON API" exists
      And all of this is happening at exactly "2012-May-01 14:10"
      And the aliquots in the library tube called "Testing the JSON API" have been modified

    And the UUID for the library tube "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    When I GET the API path "/library_tubes/00000000-1111-2222-3333-444444444444"
    Then ignoring "id|sample_name" the JSON should be:
      """
      {
        "library_tube": {
          "name": "Testing the JSON API",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2012-05-01T14:10:00+01:00",
          "uuid": "00000000-1111-2222-3333-444444444444",
          "barcode_prefix": "NT",
          "scanned_in_date": "",
          "lanes": "http://localhost:3000/0_5/library_tubes/00000000-1111-2222-3333-444444444444/lanes",
          "requests": "http://localhost:3000/0_5/library_tubes/00000000-1111-2222-3333-444444444444/requests",
          "qc_state": "",

          "id": 1
        }
      }
      """
