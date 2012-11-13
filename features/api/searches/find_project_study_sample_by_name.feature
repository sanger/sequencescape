@api @json @study @project @sample @search @single-sign-on @new-api
Feature: Searching for studies, projects and samples by name
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    Given there are no samples

  @single
  Scenario Outline: Looking for a single entry
    Given the UUID for the search "Find <model> by name" is "00000000-1111-2222-3333-444444444444"

    Given a <model> called "Testing_the_API_1" with ID 1
      And the UUID for the <model> "Testing_the_API_1" is "11111111-2222-3333-4444-000000000001"

    Given a <model> called "Testing_the_API_2" with ID 2
      And the UUID for the <model> "Testing_the_API_2" is "11111111-2222-3333-4444-000000000002"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "name": "Testing_the_API_2"
        }
      }
      """
    Then the HTTP response should be "301 Moved Permanently"
     And the JSON should match the following for the specified fields:
      """
      {
        "<model>": {
          "uuid": "11111111-2222-3333-4444-000000000002",
          <name json>
        }
      }
      """

    Examples:
      | model   | name json                                 |
      | project | "name": "Testing_the_API_2"               |
      | study   | "name": "Testing_the_API_2"               |
      | sample  | "sanger": { "name": "Testing_the_API_2" } |

  @single
  Scenario: Looking for a non-existant entry
    Given the UUID for the search "Find assets by barcode" is "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "name": "Testing the API 2"
        }
      }
      """
    Then the HTTP response should be "404 Not Found"
     And the JSON should be:
      """
      { "general": [ "no resources found with that search criteria" ] }
      """
