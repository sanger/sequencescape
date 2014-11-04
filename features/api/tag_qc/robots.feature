@api @json @single-sign-on @new-api
Feature: Access robots through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to read individual robots through their UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given I have a robot for testing called "Marvin"
      And the UUID for the robot "Marvin" is "11111111-2222-3333-4444-555555555555"

  @read
  Scenario: Reading the JSON for a UUID

    When I make an authorised GET of the API path "/11111111-2222-3333-4444-555555555555"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "robot": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "name": "Marvin",
          "robot_properties": {
            "max_plates" : "3",
            "SCRC1":"20001",
            "DEST1":"20002",
            "DEST2":"20003"
          },

          "uuid": "11111111-2222-3333-4444-555555555555"
        }
      }
      """
