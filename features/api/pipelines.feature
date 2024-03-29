@api @json @pipeline @single-sign-on @new-api @ap
Feature: Access pipelines through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual pipelines through their UUID
  And I want to be able to perform other operations to individual pipelines
  And I want to be able to do all of this only knowing the UUID of a pipeline
  And I understand I will never be able to delete a pipeline through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

    Given the UUID for the pipeline "Cluster formation PE" is "00000000-1111-2222-3333-444444444444"

  @read
  Scenario: Reading the JSON for a UUID
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "pipeline": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "batches": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/batches"
            }
          },
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/requests"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Cluster formation PE"
        }
      }
      """
    And the JSON "pipeline.batches.actions.create" should not exist

  @read @request
  Scenario Outline: Non-pending or held requests should not show up
    Given I have a request for "Cluster formation PE"
    And the last request is in the "<state>" state
    Given all requests have sequential UUIDs based on "99999999-1111-2222-3333"

    When I GET the API path "/00000000-1111-2222-3333-444444444444/requests"
    Then the HTTP response should be "200 OK"
    And the JSON should be:
      """
      {
        "actions": {
          "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/requests/1",
          "first": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/requests/1",
          "last": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/requests/1"
        },
        "size": 0,
        "requests": [ ]
      }
      """

    Examples:
      | state     |
      | started   |
      | failed    |
      | passed    |
      | cancelled |
      | blocked   |

  @read @authorised
  Scenario: Reading the JSON for a UUID
    When I make an authorised GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "pipeline": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "batches": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/batches",
              "create": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/batches"
            }
          },
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/requests"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Cluster formation PE"
        }
      }
      """

  @create @batch @authorised @error
  Scenario Outline: Attempting to create a batch with invalid request details
    Given the maximum batch size for the pipeline "Cluster formation PE" is 2

    Given there are 4 "Paired end sequencing" requests with IDs starting at 1
    And all requests have sequential UUIDs based on "11111111-2222-3333-4444"

    Given a "Library creation" request with ID 10
    And the UUID for the request with ID 10 is "99999999-1111-2222-3333-444444444444"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444/batches":
      """
      {
        "batch": {
          "requests": [ <uuids> ]
        }
      }
      """
    Then the HTTP response should be "422 Unprocessible Entity"
    And the JSON should be:
      """
      {
        "content": {
          "requests": [ <errors> ]
        }
      }
      """

    Scenarios:
      | uuids                                                                                                                  | errors                        |
      | "11111111-2222-3333-4444-000000000001", "11111111-2222-3333-4444-000000000002", "11111111-2222-3333-4444-000000000003" | "too many requests specified" |
      | "99999999-1111-2222-3333-444444444444"                                                                                 | "has incorrect type"          |


  @create @batch @authorised
  Scenario: Create a batch of requests for our pipeline
    Given the UUID of the next batch created will be "22222222-3333-4444-5555-666666666666"

    Given there are 4 "Paired end sequencing" requests with IDs starting at 1
    And all of the requests have appropriate assets with samples
    And all requests have sequential UUIDs based on "11111111-2222-3333-4444"
    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444/batches":
      """
      {
        "batch": {
          "requests": [
            "11111111-2222-3333-4444-000000000001",
            "11111111-2222-3333-4444-000000000002",
            "11111111-2222-3333-4444-000000000003"
          ]
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            "read": "http://www.example.com/api/1/22222222-3333-4444-5555-666666666666"
          },
          "pipeline": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
            }
          },
          "user": {
            "login": "John Smith"
          },

          "state": "pending",
          "requests": [
            { "uuid": "11111111-2222-3333-4444-000000000001" },
            { "uuid": "11111111-2222-3333-4444-000000000002" },
            { "uuid": "11111111-2222-3333-4444-000000000003" }
          ]
        }
      }
      """
