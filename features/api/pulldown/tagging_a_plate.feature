@api @json @single-sign-on @new-api
Feature: Tagging the wells on a plate using a tag layout template
  There are several points in the pulldown laboratory workflow where the contents of a plate are tagged.  Taking
  WGS as an example: the user will create a WGS lib PCR from a WGS lib, they will then start
  that WGS lib PCR, then assign the tags, do the PCR reaction, and then pass the WGS lib PCR.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the UUID for the search "Find assets by barcode" is "33333333-4444-5555-6666-000000000001"

    # Really this should be seed data but ...
    Given the tag layout template "Pulldown 8 tag set in column major order" exists
      And the UUID for the tag layout template "Pulldown 8 tag set in column major order" is "22222222-3333-4444-5555-000000000001"
      And the tag group for tag layout template "Pulldown 8 tag set in column major order" is called "Pulldown 8 tag set"
      And the tag group for tag layout template "Pulldown 8 tag set in column major order" contains the following tags:
        | index | oligo |
        | 1     | AAAA  |
        | 2     | CCCC  |
        | 3     | TTTT  |
        | 4     | GGGG  |
        | 5     | AACC  |
        | 6     | TTGG  |
        | 7     | AATT  |
        | 8     | CCGG  |

    Given the UUID for the transfer template "Transfer columns 1-12" is "22222222-3333-4444-5555-000000000002"

  @tag_layout @tag_layout_template @barcode-service
  Scenario Outline: Creating the plate to be tagged and assigning tags
    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given the UUID for the plate purpose "<parent plate type>" is "11111111-2222-3333-4444-000000000001"
      And the UUID for the plate purpose "<child plate type>" is "11111111-2222-3333-4444-000000000002"
      And a "<parent plate type>" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"
      And all wells on the plate "Testing the API" have unique samples

    Given the UUID of the next plate created will be "00000000-1111-2222-3333-000000000002"
      And the UUID of the next tag layout created will be "22222222-3333-4444-5555-000000000002"

    # Find the plate by barcode
    When I POST the following JSON to the API path "/33333333-4444-5555-6666-000000000001/first":
      """
      {
        "search": {
          "barcode": "1221000001777"
        }
      }
      """
    Then the HTTP response should be "301 Moved Permanently"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "name": "Testing the API",
          "uuid": "00000000-1111-2222-3333-000000000001"
        }
      }
      """

    # Create the child plate
    When I make an authorised POST with the following JSON to the API path "/11111111-2222-3333-4444-000000000002/plates":
      """
      {
        "plate": { }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate_purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000002"
            }
          },
          "uuid": "00000000-1111-2222-3333-000000000002"
        }
      }
      """

    # Make the transfers between the two plates
    When I make an authorised POST with the following JSON to the API path "/22222222-3333-4444-5555-000000000002":
      """
      {
        "transfer": {
          "user": "99999999-8888-7777-6666-555555555555",
          "source": "00000000-1111-2222-3333-000000000001",
          "destination": "00000000-1111-2222-3333-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "00000000-1111-2222-3333-000000000001"
          },
          "destination": {
            "uuid": "00000000-1111-2222-3333-000000000002"
          },
          "transfers": {
            "A1":  "A1",
            "A2":  "A2",
            "A3":  "A3",
            "A4":  "A4",
            "A5":  "A5",
            "A6":  "A6",
            "A7":  "A7",
            "A8":  "A8",
            "A9":  "A9",
            "A10": "A10",
            "A11": "A11",
            "A12": "A12",

            "B1":  "B1",
            "B2":  "B2",
            "B3":  "B3",
            "B4":  "B4",
            "B5":  "B5",
            "B6":  "B6",
            "B7":  "B7",
            "B8":  "B8",
            "B9":  "B9",
            "B10": "B10",
            "B11": "B11",
            "B12": "B12",

            "C1":  "C1",
            "C2":  "C2",
            "C3":  "C3",
            "C4":  "C4",
            "C5":  "C5",
            "C6":  "C6",
            "C7":  "C7",
            "C8":  "C8",
            "C9":  "C9",
            "C10": "C10",
            "C11": "C11",
            "C12": "C12",

            "D1":  "D1",
            "D2":  "D2",
            "D3":  "D3",
            "D4":  "D4",
            "D5":  "D5",
            "D6":  "D6",
            "D7":  "D7",
            "D8":  "D8",
            "D9":  "D9",
            "D10": "D10",
            "D11": "D11",
            "D12": "D12",

            "E1":  "E1",
            "E2":  "E2",
            "E3":  "E3",
            "E4":  "E4",
            "E5":  "E5",
            "E6":  "E6",
            "E7":  "E7",
            "E8":  "E8",
            "E9":  "E9",
            "E10": "E10",
            "E11": "E11",
            "E12": "E12",

            "F1":  "F1",
            "F2":  "F2",
            "F3":  "F3",
            "F4":  "F4",
            "F5":  "F5",
            "F6":  "F6",
            "F7":  "F7",
            "F8":  "F8",
            "F9":  "F9",
            "F10": "F10",
            "F11": "F11",
            "F12": "F12",

            "G1":  "G1",
            "G2":  "G2",
            "G3":  "G3",
            "G4":  "G4",
            "G5":  "G5",
            "G6":  "G6",
            "G7":  "G7",
            "G8":  "G8",
            "G9":  "G9",
            "G10": "G10",
            "G11": "G11",
            "G12": "G12",

            "H1":  "H1",
            "H2":  "H2",
            "H3":  "H3",
            "H4":  "H4",
            "H5":  "H5",
            "H6":  "H6",
            "H7":  "H7",
            "H8":  "H8",
            "H9":  "H9",
            "H10": "H10",
            "H11": "H11",
            "H12": "H12"
          }
        }
      }
      """

    # Assigning the tags
    When I make an authorised POST with the following JSON to the API path "/22222222-3333-4444-5555-000000000001":
      """
      {
        "tag_layout": {
          "user": "99999999-8888-7777-6666-555555555555",
          "plate": "00000000-1111-2222-3333-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },

          "uuid": "22222222-3333-4444-5555-000000000002",

          "tag_group": {
            "name": "Pulldown 8 tag set",
            "tags": {
              "1": "AAAA",
              "2": "CCCC",
              "3": "TTTT",
              "4": "GGGG",
              "5": "AACC",
              "6": "TTGG",
              "7": "AATT",
              "8": "CCGG"
            }
          }
        }
      }
      """

    Scenarios:
      | parent plate type         | child plate type              |
      | WGS lib         | WGS lib PCR         |
      | SC cap lib | SC cap lib PCR |
      | ISC lib         | ISC lib PCR         |


