@api @json @plate @single-sign-on @new-api
Feature: Access plates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual plates through their UUID
  And I want to be able to perform other operations to individual plates
  And I want to be able to do all of this only knowing the UUID of a plate
  And I understand I will never be able to delete a plate through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given the plate exists with ID 1
      And the plate with ID 1 has a barcode of "1220000001831"
      And the UUID for the plate with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the plate with ID 1 has a plate purpose of "Stock plate"
      And the UUID for the plate purpose "Stock plate" is "11111111-2222-3333-4444-555555555555"
      And the plate with ID 1 has a custom metadatum collection with UUID "11111111-2222-3333-4444-666666666666"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "plate_purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },
          "wells": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/wells"
            }
          },
          "submission_pools": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/submission_pools"
            }
          },
          "custom_metadatum_collection": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666"
            }
          },


          "barcode": {
            "prefix": "DN",
            "number": "1",
            "ean13": "1220000001831",
            "type": 1
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """
