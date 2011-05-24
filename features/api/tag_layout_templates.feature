@api @json @tag_layout_template @single-sign-on @new-api
Feature: Access tag layout templates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual tag layout templates through their UUID
  And I want to be able to perform other operations to individual tag layout templates
  And I want to be able to do all of this only knowing the UUID of a tag layout template
  And I understand I will never be able to delete a tag layout template through its UUID

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
    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo |
        | 1     | ACTG  |
        | 2     | GTCA  |

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Test tag layout",

          "tag_group": {
            "name": "Tag group 1",
            "tags": {
              "1": "ACTG",
              "2": "GTCA"
            }
          }
        }
      }
      """

  @tag_layout @create
  Scenario: Creating a tag layout from a tag layout template
    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-444444444444"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo |
        | 1     | AAAA  |
        | 2     | CCCC  |
        | 3     | TTTT  |
        | 4     | GGGG  |
        | 5     | AACC  |
        | 6     | TTGG  |
        | 7     | AATT  |
        | 8     | CCGG  |
      And the UUID of the next tag layout created will be "00000000-1111-2222-3333-000000000002"

    Given a "Stock plate" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "11111111-2222-3333-4444-000000000001"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "tag_layout": {
          "plate": "11111111-2222-3333-4444-000000000001"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tag_layout": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
          },
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
            }
          },

          "uuid": "00000000-1111-2222-3333-000000000002",

          "tag_group": {
            "name": "Tag group 1",
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

    Then the tags assigned to the plate "Testing the API" should be:
      | well | tag  |
      | A1   | AAAA |
      | B1   | CCCC |
      | C1   | TTTT |
      | D1   | GGGG |
      | E1   | AACC |
      | F1   | TTGG |
      | G1   | AATT |
      | H1   | CCGG |
      | A2   | AAAA |
      | B2   | CCCC |
      | C2   | TTTT |
      | D2   | GGGG |
      | E2   | AACC |
      | F2   | TTGG |
      | G2   | AATT |
      | H2   | CCGG |
      | A3   | AAAA |
      | B3   | CCCC |
      | C3   | TTTT |
      | D3   | GGGG |
      | E3   | AACC |
      | F3   | TTGG |
      | G3   | AATT |
      | H3   | CCGG |
      | A4   | AAAA |
      | B4   | CCCC |
      | C4   | TTTT |
      | D4   | GGGG |
      | E4   | AACC |
      | F4   | TTGG |
      | G4   | AATT |
      | H4   | CCGG |
      | A5   | AAAA |
      | B5   | CCCC |
      | C5   | TTTT |
      | D5   | GGGG |
      | E5   | AACC |
      | F5   | TTGG |
      | G5   | AATT |
      | H5   | CCGG |
      | A6   | AAAA |
      | B6   | CCCC |
      | C6   | TTTT |
      | D6   | GGGG |
      | E6   | AACC |
      | F6   | TTGG |
      | G6   | AATT |
      | H6   | CCGG |
      | A7   | AAAA |
      | B7   | CCCC |
      | C7   | TTTT |
      | D7   | GGGG |
      | E7   | AACC |
      | F7   | TTGG |
      | G7   | AATT |
      | H7   | CCGG |
      | A8   | AAAA |
      | B8   | CCCC |
      | C8   | TTTT |
      | D8   | GGGG |
      | E8   | AACC |
      | F8   | TTGG |
      | G8   | AATT |
      | H8   | CCGG |
      | A9   | AAAA |
      | B9   | CCCC |
      | C9   | TTTT |
      | D9   | GGGG |
      | E9   | AACC |
      | F9   | TTGG |
      | G9   | AATT |
      | H9   | CCGG |
      | A10  | AAAA |
      | B10  | CCCC |
      | C10  | TTTT |
      | D10  | GGGG |
      | E10  | AACC |
      | F10  | TTGG |
      | G10  | AATT |
      | H10  | CCGG |
      | A11  | AAAA |
      | B11  | CCCC |
      | C11  | TTTT |
      | D11  | GGGG |
      | E11  | AACC |
      | F11  | TTGG |
      | G11  | AATT |
      | H11  | CCGG |
      | A12  | AAAA |
      | B12  | CCCC |
      | C12  | TTTT |
      | D12  | GGGG |
      | E12  | AACC |
      | F12  | TTGG |
      | G12  | AATT |
      | H12  | CCGG |
