@api @json @request @single-sign-on @new-api
Feature: Access requests through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual requests through their UUID
  And I want to be able to perform other operations to individual requests
  And I want to be able to do all of this only knowing the UUID of a request
  And I understand I will never be able to delete a request through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have a project called "My project"
    And the UUID for the project "My project" is "11111111-1111-2222-3333-444444444444"

    Given I have an active study called "Testing the requests API"
    And the UUID for the study "Testing the requests API" is "11111111-2222-3333-4444-000000000000"
    And I have a library tube of stuff called "tube_1"
    And the UUID for the library tube "tube_1" is "11111111-3333-4444-5555-666666666666"

  @paging
  Scenario Outline: Retrieving the page of requests when only one page exists
    Given I have already made a "<request type name>" request with ID 1 within the study "Testing the requests API" for the project "My project"
    And the UUID for the <request type> request with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/requests"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "actions": {
          "read": "http://www.example.com/api/1/requests/1",
          "first": "http://www.example.com/api/1/requests/1",
          "last": "http://www.example.com/api/1/requests/1"
        },
        "requests": [
          {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
            },

            "uuid": "00000000-1111-2222-3333-444444444444",
            "state": "pending",

            "type": "<request type name>",
            "fragment_size": {
              "from": "<fragment size from>",
              "to": "<fragment size to>"
            },

            "source_asset": {
              "type": "<asset type>",
              "name": "Testing the requests API - Source asset 1"
            },
            "target_asset": {
              "type": "<asset type>",
              "name": "Testing the requests API - Target asset 1"
            }
          }
        ]
      }
      """

    Examples:
      | request type                 | request type name            | asset type    | fragment size from | fragment size to |
      | library creation             | Library creation             | sample_tubes  | 1                  | 20               |
      | multiplexed library creation | Multiplexed library creation | sample_tubes  | 1                  | 20               |
      | sequencing                   | Paired end sequencing        | library_tubes | 1                  | 21               |
      | sequencing                   | Single ended sequencing      | library_tubes | 1                  | 21               |

