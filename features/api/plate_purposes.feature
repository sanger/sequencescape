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
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
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

          "wells": [
            { "location": "A1"  },
            { "location": "A2"  },
            { "location": "A3"  },
            { "location": "A4"  },
            { "location": "A5"  },
            { "location": "A6"  },
            { "location": "A7"  },
            { "location": "A8"  },
            { "location": "A9"  },
            { "location": "A10" },
            { "location": "A11" },
            { "location": "A12" },

            { "location": "B1"  },
            { "location": "B2"  },
            { "location": "B3"  },
            { "location": "B4"  },
            { "location": "B5"  },
            { "location": "B6"  },
            { "location": "B7"  },
            { "location": "B8"  },
            { "location": "B9"  },
            { "location": "B10" },
            { "location": "B11" },
            { "location": "B12" },

            { "location": "C1"  },
            { "location": "C2"  },
            { "location": "C3"  },
            { "location": "C4"  },
            { "location": "C5"  },
            { "location": "C6"  },
            { "location": "C7"  },
            { "location": "C8"  },
            { "location": "C9"  },
            { "location": "C10" },
            { "location": "C11" },
            { "location": "C12" },

            { "location": "D1"  },
            { "location": "D2"  },
            { "location": "D3"  },
            { "location": "D4"  },
            { "location": "D5"  },
            { "location": "D6"  },
            { "location": "D7"  },
            { "location": "D8"  },
            { "location": "D9"  },
            { "location": "D10" },
            { "location": "D11" },
            { "location": "D12" },

            { "location": "E1"  },
            { "location": "E2"  },
            { "location": "E3"  },
            { "location": "E4"  },
            { "location": "E5"  },
            { "location": "E6"  },
            { "location": "E7"  },
            { "location": "E8"  },
            { "location": "E9"  },
            { "location": "E10" },
            { "location": "E11" },
            { "location": "E12" },

            { "location": "F1"  },
            { "location": "F2"  },
            { "location": "F3"  },
            { "location": "F4"  },
            { "location": "F5"  },
            { "location": "F6"  },
            { "location": "F7"  },
            { "location": "F8"  },
            { "location": "F9"  },
            { "location": "F10" },
            { "location": "F11" },
            { "location": "F12" },

            { "location": "G1"  },
            { "location": "G2"  },
            { "location": "G3"  },
            { "location": "G4"  },
            { "location": "G5"  },
            { "location": "G6"  },
            { "location": "G7"  },
            { "location": "G8"  },
            { "location": "G9"  },
            { "location": "G10" },
            { "location": "G11" },
            { "location": "G12" },

            { "location": "H1"  },
            { "location": "H2"  },
            { "location": "H3"  },
            { "location": "H4"  },
            { "location": "H5"  },
            { "location": "H6"  },
            { "location": "H7"  },
            { "location": "H8"  },
            { "location": "H9"  },
            { "location": "H10" },
            { "location": "H11" },
            { "location": "H12" }
          ],

          "uuid": "22222222-1111-2222-3333-444444444444"
        }
      }
      """
