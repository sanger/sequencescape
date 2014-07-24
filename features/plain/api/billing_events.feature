@api @json @billing_event @allow-rescue
Feature: Interacting with billing_events through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the billing_events that exist if there aren't any
    When I GET the API path "/billing_events"
    Then the JSON should be an empty array

  Scenario: Listing all of the billing_events that exist
    Given I have a billing event with UUID "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/billing_events"
    Then ignoring "updated_at|internal_id|project_internal_id|project_uuid|request_uuid|request_internal_id|reference" the JSON should be:
      """
      [
        {
          "billing_event": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "quantity": 1,
            "kind": "charge",
            "description": "Unspecified",
            "project_name": "Test Project",
            "created_by": "abc123@example.com",
            "project_division": "Human variation",
            "project_cost_code": "Some Cost Code",
            "entry_date": "2010-09-16T13:45:00+01:00",
            "created_at": "2010-09-16T13:45:00+01:00",
            "price": 100,
            "request_type": "Paired end sequencing",
            "library_type": "Standard",

            "internal_id": 1,
            "project_internal_id": 2,
            "project_uuid": "UUID-11111",
            "request_uuid": "UUID-22222",
            "request_internal_id": 3,
            "reference": "R123A456"
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a billing_event that does not exist
    When I GET the API path "/billing_events/UUID-xxxxxxx"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular billing_event
    Given I have a billing event with UUID "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/billing_events/00000000-1111-2222-3333-444444444444"
    Then ignoring "updated_at|internal_id|project_internal_id|project_uuid|request_uuid|request_internal_id|reference" the JSON should be:
      """
      {
        "billing_event": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "quantity": 1,
          "kind": "charge",
          "description": "Unspecified",
          "project_name": "Test Project",
          "created_by": "abc123@example.com",
          "project_division": "Human variation",
          "project_cost_code": "Some Cost Code",
          "entry_date": "2010-09-16T13:45:00+01:00",
          "created_at": "2010-09-16T13:45:00+01:00",
          "price": 100,
          "request_type": "Paired end sequencing",
          "library_type": "Standard",

          "internal_id": 1,
          "project_internal_id": 2,
          "project_uuid": "UUID-11111",
          "request_uuid": "UUID-22222",
          "request_internal_id": 3,
          "reference": "R123A456"
        }
      }
      """
