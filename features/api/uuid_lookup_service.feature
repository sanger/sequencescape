@api @json @uuid @lookup @single-sign-on @new-api
Feature: The API provides a lookup feature for legacy ID values to UUIDs
  In order to be able to map the internal IDs I have stored from previous API versions to the new UUIDs
  As an authenticated user of the API
  I want to be able to lookup a single UUID based on the model and internal ID and be redirected to the resource
  And I want to be able to lookup multiple UUIDs and be given a list of their mappings

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given there are no samples

  @error
  Scenario Outline: Not authenticated if the WTSISignOn cookie is not sent
    Given no cookies are set for HTTP requests to the API

    When I POST the following JSON to the API path "/uuids/<service>":
      """
      {
        "lookup": <json>
      }
      """
    Then the HTTP response should be "401 Unauthorized"
    And the JSON should be:
      """
      {
        "general": [ "no WTSISignOn cookie provided" ]
      }
      """

    Examples:
      | service | json                               |
      | lookup  | { "model": "sample", "id": 1 }     |
      | bulk    | [ { "model": "sample", "id": 1 } ] |

  @error
  Scenario Outline: Not authenticated if the single sign-on service says you are not
    Given the WTSI single sign-on service does not recognise "I-am-authenticated"

    When I POST the following JSON to the API path "/uuids/<service>":
      """
      {
        "lookup": <json>
      }
      """
    Then the HTTP response should be "401 Unauthorized"
    And the JSON should be:
      """
      {
        "general": [ "the WTSISignOn cookie is invalid" ]
      }
      """

    Examples:
      | service | json                               |
      | lookup  | { "model": "sample", "id": 1 }     |
      | bulk    | [ { "model": "sample", "id": 1 } ] |

  @error @individual
  Scenario: Looking up a single record that does not exist
    When I POST the following JSON to the API path "/uuids/lookup":
      """
      {
        "lookup": {
          "model": "sample",
          "id": 1
        }
      }
      """
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "Unable to find UUID" ]
      }
      """

  @individual
  Scenario: Looking up a single record
    Given the sample named "testing_the_uuid_lookup_service" exists with ID 1
    And the UUID for the sample "testing_the_uuid_lookup_service" is "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/uuids/lookup":
      """
      {
        "lookup": {
          "model": "sample",
          "id": 1
        }
      }
      """
    Then the HTTP response should be "301 Moved Permanently"
    And the HTTP "Location" should be "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
    And the JSON should be:
      """
      {
        "model": "sample",
        "id":    1,
        "uuid":  "00000000-1111-2222-3333-444444444444",
        "url":   "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
      }
      """

  @bulk
  Scenario: Looking up multiple records
    Given the sample named "testing_the_uuid_lookup_service_1" exists with ID 1
    And the UUID for the sample "testing_the_uuid_lookup_service_1" is "00000000-1111-2222-3333-444444444444"
    And the sample named "testing_the_uuid_lookup_service_2" exists with ID 2
    And the UUID for the sample "testing_the_uuid_lookup_service_2" is "00000000-1111-2222-3333-555555555555"

    When I POST the following JSON to the API path "/uuids/bulk":
      """
      {
        "lookup": [
          { "model": "sample", "id": 1 },
          { "model": "sample", "id": 2 }
        ]
      }
      """
    Then the HTTP response should be "300 Multiple Choices"
    And the JSON should be:
      """
      [
        {
          "model": "sample",
          "id":    1,
          "uuid":  "00000000-1111-2222-3333-444444444444",
          "url":   "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
        },
        {
          "model": "sample",
          "id":    2,
          "uuid":  "00000000-1111-2222-3333-555555555555",
          "url":   "http://www.example.com/api/1/00000000-1111-2222-3333-555555555555"
        }
      ]
      """

  @error
  Scenario Outline: Invalid parameters for UUID lookups
    When I POST the following JSON to the API path "/uuids/<service>":
      """
      <posted_json>
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          <errors>
        }
      }
      """

    @individual
    Scenarios: Individual lookup
      | service | posted_json                          | errors                                                                             |
      | lookup  | {"lookup":{"model":"study", "id":0}} | "id":["must be greater than 0"]                                                    |
      | lookup  | {"lookup":{"model":"study"}}         | "id":["is not a number"]                                                           |
      | lookup  | {"lookup":{"model":"", "id":1}}      | "model":["can't be blank"]                                                         |
      | lookup  | {}                                   | "lookup":["should be a tuple"],"model":["can't be blank"],"id":["is not a number"] |
      | lookup  |                                      | "lookup":["should be a tuple"],"model":["can't be blank"],"id":["is not a number"] |

    @bulk
    Scenarios: Bulk lookup
      | service | posted_json        | errors                                    |
      | bulk    | {"lookup":["foo"]} | "lookup":["should be a tuple"]            |
      | bulk    | {"lookup":[]}      | "lookup":["can't be blank"]               |
      | bulk    | {}                 | "lookup":["should be an array of tuples"] |
      | bulk    |                    | "lookup":["should be an array of tuples"] |

    @wip
    Scenarios: Where the JSON is completely invalid
      | service | posted_json                        | errors                                    |
      | lookup  | {"lookup":{"model":"foo", "id":1}} | "model":["is not included in the list"]   |
      | lookup  | []                                 | "lookup":["should be a tuple"]            |
      | bulk    | []                                 | "lookup":["should be an array of tuples"] |

  @error @wip
  Scenario Outline: Unsupported HTTP methods
    When I <method> the API path "/uuids/<service>"
    Then the HTTP response should be "405 Method Not Allowed"
    And the HTTP "Allow" should be "POST"
    And the JSON should be:
      """
      {
        "general": [ "unsupported action" ]
      }
      """

    @individual
    Scenarios: Individual lookup
      | service | method |
      | lookup  | GET    |
      | lookup  | PUT    |
      | lookup  | DELETE |

    @bulk
    Scenarios: Bulk lookup
      | service | method |
      | bulk    | GET    |
      | bulk    | PUT    |
      | bulk    | DELETE |
