@api @json @well @single-sign-on @new-api
Feature: Access wells through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual wells through their UUID
  And I want to be able to perform other operations to individual wells
  And I want to be able to do all of this only knowing the UUID of a well
  And I understand I will never be able to delete a well through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given the well exists with ID 1
    And the UUID for the well with ID 1 is "00000000-1111-2222-3333-444444444444"

    Given the plate exists with ID 10
    And the UUID for the plate with ID 10 is "11111111-2222-3333-4444-555555555555"
    And the well with ID 1 is at position "A1" on the plate with ID 10

    Given the sample called "johns_gene" exists
    And the UUID for the sample "johns_gene" is "22222222-3333-4444-5555-666666666666"
    And the well with ID 1 contains the sample "johns_gene"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "well": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "aliquots": [
            {
              "sample": {

              }
            }
          ],

          "uuid": "00000000-1111-2222-3333-444444444444",
          "location": "A1"
        }
      }
      """
