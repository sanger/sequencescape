@api @json @single-sign-on @new-api
Feature: Tagging the wells on a plate using a tag layout template
  There are several points in the pulldown laboratory workflow where the contents of a plate are tagged.  Taking
  WGS as an example: the user will create a WGS library PCR plate from a WGS library plate, they will then start
  that WGS library PCR plate, then assign the tags, do the PCR reaction, and then pass the WGS library PCR plate.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given the UUID for the search "Find asset by barcode" is "33333333-4444-5555-6666-000000000001"

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

  @tag_layout @tag_layout_template @barcode-service
  Scenario Outline: Creating the plate to be tagged and assigning tags
    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given the UUID for the plate purpose "<parent plate type>" is "11111111-2222-3333-4444-000000000001"
      And the UUID for the plate purpose "<child plate type>" is "11111111-2222-3333-4444-000000000002"
      And a "<parent plate type>" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"

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

    # Assigning the tags
    When I POST the following JSON to the API path "/22222222-3333-4444-5555-000000000001":
      """
      {
        "tag_layout": {
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
      | WGS library plate         | WGS library PCR plate         |
      | SC captured library plate | SC captured library PCR plate |
      | ISC library plate         | ISC library PCR plate         |


