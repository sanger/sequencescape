@api @json @sample @single-sign-on @new-api
Feature: Access samples through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to read individual samples through their UUID
  And I want to be able to perform other operations to individual samples
  And I want to be able to do all of this only knowing the UUID of a sample
  And I understand I will never be able to delete a sample through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

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
    Given a sample called "testing_the_api_exists" with ID 1
    And the UUID for the sample with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "sample_tubes": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_tubes"
            }
          }
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """
