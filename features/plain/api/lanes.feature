@api @json @lane @asset @allow-rescue @wip
Feature: Interacting with lanes through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the lanes that exist if there aren't any
    When I GET the API path "/lanes"
    Then the JSON should be an empty array

  Scenario: Listing all of the lanes that exist
    Given a lane called "Testing the JSON API" exists
    And the UUID for the lane "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And lane "00000000-1111-2222-3333-444444444444" has qc_state "pending"

    When I GET the API path "/lanes"
    Then ignoring "internal_id" the JSON should be:
      """
      [
        {
          "lane": {
            "name": "Testing the JSON API",
            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00",
            "uuid": "00000000-1111-2222-3333-444444444444",
            "barcode_prefix": "NT",
            "qc_state": "pending",
            "requests": "http://localhost:3000/0_5/lanes/00000000-1111-2222-3333-444444444444/requests",
            "internal_id": 1
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a lane that does not exist
    When I GET the API path "/lanes/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular lane
    Given a lane called "Testing the JSON API" exists
    And the UUID for the lane "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And lane "00000000-1111-2222-3333-444444444444" has qc_state "pending"

    When I GET the API path "/lanes/00000000-1111-2222-3333-444444444444"
    Then ignoring "internal_id" the JSON should be:
      """
      {
        "lane": {
          "name": "Testing the JSON API",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",
          "uuid": "00000000-1111-2222-3333-444444444444",
          "requests": "http://localhost:3000/0_5/lanes/00000000-1111-2222-3333-444444444444/requests",
          "barcode_prefix": "NT",
          "qc_state": "pending",

          "internal_id": 1
        }
      }
      """
