@api @json @plate_purpose @single-sign-on @new-api
Feature: Access plate purposes through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual plate purposes through their UUID
  And I want to be able to perform other operations to individual plate purposes
  And I want to be able to do all of this only knowing the UUID of a plate purpose
  And I understand I will never be able to delete a plate purpose through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given no plate purposes exist

  @read
  Scenario: Reading the JSON for a UUID
    Given the plate purpose exists with ID 1
    And the UUID for the plate purpose with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "plate_purpose": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "name": "Frag",
          "plates": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/plates"
            }
          },
          "children": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/children"
            }
          }
        }
      }
      """

  @create @plate @unauthorised @error
  Scenario: Attempting to create a plate without authorisation errors
    Given the plate purpose exists with ID 1
    And the UUID for the plate purpose with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/plates":
      """
      {
        "plate": {

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

  @create @plate @authorised @barcode-service
  Scenario: Creating a plate with a bunch of wells from the plate purpose
    Given the plate barcode webservice returns "1000001"

    Given the plate purpose exists with ID 1
      And the UUID for the plate purpose with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the UUID of the next plate created will be "22222222-1111-2222-3333-444444444444"

    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444/plates":
      """
      {
        "plate": {

        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "actions": {
            "read": "http://www.example.com/api/1/22222222-1111-2222-3333-444444444444"
          },

          "wells": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-1111-2222-3333-444444444444/wells"
            },
            "size": 96
          },

          "uuid": "22222222-1111-2222-3333-444444444444"
        }
      }
      """
