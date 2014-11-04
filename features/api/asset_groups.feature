@api @json @asset_group @single-sign-on @new-api
Feature: Access asset groups through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual asset groups through their UUID
  And I want to be able to perform other operations to individual asset groups
  And I want to be able to do all of this only knowing the UUID of a asset group
  And I understand I will never be able to delete a asset group through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given I have an "active" study called "Testing asset groups"
    And the UUID for the study "Testing asset groups" is "11111111-2222-3333-4444-555555555555"

    Given the study "Testing asset groups" has an asset group called "Testing the API"
    And the UUID for the asset group "Testing the API" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "asset_group": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Testing the API",

          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            },
            "name": "Testing asset groups"
          },
          "assets": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/assets"
            }
          }
        }
      }
      """
