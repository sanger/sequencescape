@api @json @dilution_plate_purpose @single-sign-on @new-api
Feature: Access dilution plate purposes through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual dilution plate purposes through their UUID
  And I want to be able to perform other operations to individual dilution plate purposes
  And I want to be able to do all of this only knowing the UUID of a dilution plate purpose
  And I understand I will never be able to delete a dilution plate purpose through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given no plate purposes exist

  @read
  Scenario: Reading the JSON for a UUID
    Given the dilution plate purpose exists with ID 1
    And the UUID for the dilution plate purpose with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "dilution_plate_purpose": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "name": "Dilution",
          "plates": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/plates"
            }
          }
        }
      }
      """
