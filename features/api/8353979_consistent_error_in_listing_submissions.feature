@api @json @submission @single-sign-on @new-api @regression
Feature: Consistent errors reported by API when listing all submissions
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have an "active" study called "Testing submissions"
    And the UUID for the study "Testing submissions" is "22222222-3333-4444-5555-000000000000"

    Given I have a project called "Testing submissions"
    And the UUID for the project "Testing submissions" is "22222222-3333-4444-5555-000000000001"

  @read
  Scenario: When the submission has no request types, because it's broken
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"

    Given I have a submission created with the following details based on the template "Library creation - Paired end sequencing":
      | study            | 22222222-3333-4444-5555-000000000000                                                                       |
      | project          | 22222222-3333-4444-5555-000000000001                                                                       |
      | request_options  | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      | assets           | 33333333-4444-5555-6666-000000000001                                                                       |
    And the submission with UUID "11111111-2222-3333-4444-555555555555" has no request types

    When I GET the API path "/11111111-2222-3333-4444-555555555555"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "state": "building",
          "request_options": { }
        }
      }
      """
