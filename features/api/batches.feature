@api @json @batch @single-sign-on @new-api
Feature: Access batches through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual batches through their UUID
  And I want to be able to perform other operations to individual batches
  And I want to be able to do all of this only knowing the UUID of a batch
  And I understand I will never be able to delete a batch through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have a pipeline called "Testing the API"
    And the UUID for the pipeline "Testing the API" is "11111111-2222-3333-4444-555555555555"
    And the pipeline "Testing the API" accepts "Single ended sequencing" requests

  @read @error
  Scenario: Reading the JSON for a UUID that does not exist
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "UUID does not exist" ]
      }
      """

  @read
  Scenario: Reading the JSON for a UUID
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline

    Given the user with login "John Smith" exists
    And "John Smith" is the owner of batch with ID 1

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "pipeline": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },
          "user": {
            "login": "John Smith"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "requests": [ ]
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """

  @read @authorised
  Scenario: Reading the JSON for a UUID
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline

    When I make an authorised GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "release": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/release",
            "complete": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/complete"
          },
          "pipeline": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "requests": [ ]
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """

  @update @unauthorised @error
  Scenario: Attempting to update the batch without authorisation errors
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "batch": {
          "state": "started"
        }
      }
      """
    Then the HTTP response should be "501 Internal Error"
    And the JSON should be:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """

  @update @error @authorised
  Scenario: Updating the JSON for an existing batch
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline

    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "batch": {
          "state": "started"
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "state": [ "is read-only" ]
        }
      }
      """

  @update @authorised @request
  Scenario: Updating the JSON for a request within a batch
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline
    And the last batch has 3 requests
    And all requests have sequential UUIDs based on "99999999-1111-2222-3333"

    Given a library tube called "Testing the API tube" with ID 99
    And the UUID for the library tube "Testing the API tube" is "88888888-1111-2222-3333-444444444444"

    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "batch": {
          "requests": [
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "state": "failed"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000002",
              "target_asset": "88888888-1111-2222-3333-444444444444"
            }
          ]
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "pipeline": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "requests": [ 
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "state": "failed"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000002",
              "state": "pending",
              "target_asset": {
                "name": "Testing the API tube"
              }
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000003",
              "state": "pending"
            }
          ]
        }
      }
      """

  @start @complete @release @unauthorised @error
  Scenario Outline: Attempting to perform a state altering action when the client is unauthorised
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline
    And the last batch has 3 requests
    And all requests have sequential UUIDs based on "99999999-1111-2222-3333"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444/<action>":
      """
      {
        "batch": { }
      }
      """
    Then the HTTP response should be "501 Internal Error"
    And the JSON should be:
      """
      {
        "general": [ "requested action is not supported on this resource" ]
      }
      """

    Examples:
      | action   |
      | start    |
      | complete |
      | release  |

  @start @complete @release @authorised
  Scenario Outline: Performing a state altering action
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline
    And the last batch has 3 requests
    And all requests have sequential UUIDs based on "99999999-1111-2222-3333"

    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444/<action>":
      """
      {
        "batch": { }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            <actions>
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "pipeline": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "<state>",
          "requests": [ 
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "state": "<request state>"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000002",
              "state": "<request state>"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000003",
              "state": "<request state>"
            }
          ]
        }
      }
      """

    Examples:
      | action   | state     | request state | actions                                                                                                                                                                           |
      | start    | started   | started       | "complete": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/complete", "release": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/release", |
      | complete | completed | pending       | "release": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/release",                                                                                           |
      | release  | released  | pending       |                                                                                                                                                                                   |
