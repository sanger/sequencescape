@api @json @broadcast_events @single-sign-on @new-api @barcode-service
Feature: Create library event through the API
  In order to be able to track individual library steps
  Without buttong even more buisness logic in the plate purposes
  I should be able to create lab events via the API

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"
    And a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the Baracoda barcode service returns "SQPD-1000001"
    Given the Baracoda barcode service returns "SQPD-1000002"
    And a "Cherrypicked" plate called "Testing the API" exists
    And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"

  Scenario: Creating an event
    When I make an authorised POST with the following JSON to the API path "/library_events":
      """
      {
        "library_event": {
          "user": "99999999-8888-7777-6666-555555555555",
          "seed": "00000000-1111-2222-3333-000000000001",
          "event_type": "created_the_best_plate"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    # We COULD return the actual event body here. But it would be slow, and
    # probably not all that useful.
    And the JSON should match the following for the specified fields:
      """
      {
        "library_event": {
          "user": {
            "uuid":"99999999-8888-7777-6666-555555555555"
          },
          "seed": {
            "uuid":"00000000-1111-2222-3333-000000000001"
          },
          "event_type":"created_the_best_plate"
        }
      }
      """
