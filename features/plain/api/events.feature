@api @json @event @allow-rescue
Feature: Interacting with events through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the events that exist if there aren't any
    When I GET the API path "/events"
    Then the JSON should be an empty array

  Scenario: Listing all of the events that exist
    Given I have an event with uuid "00000000-1111-2222-3333-444444444444"
    Given I have an external release event with uuid "UUID-99999999"

    When I GET the API path "/events"
    Then ignoring "internal_id" the JSON should be:
      """
      [
      {
        "event": {
          "uuid": "UUID-99999999",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",
          "message": "external release event",

          "internal_id": 1
          }
        },
        {
          "event": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00",
            "message": "event",

            "internal_id": 1
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a event that does not exist
    When I GET the API path "/events/UUID-xxxxxxx"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular event
    Given I have an event with uuid "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/events/00000000-1111-2222-3333-444444444444"
    Then ignoring "internal_id" the JSON should be:
      """
      {
        "event": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "message": "event",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",

          "internal_id": 1
        }
      }
      """
