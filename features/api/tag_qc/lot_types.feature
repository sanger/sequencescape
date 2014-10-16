@api @json @single-sign-on @new-api
Feature: Access lots through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual lots through their UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given I have a lot type for testing called "Test Lot Type"
      And the UUID for the lot type "Test Lot Type" is "11111111-2222-3333-4444-555555555555"
    Given the tag layout template "Test tag layout" exists
      And the UUID for the tag layout template "Test tag layout" is "00000000-1111-2222-3333-666666666666"
      And the tag group for tag layout template "Test tag layout" is called "Tag group 1"
      And the tag group for tag layout template "Test tag layout" contains the following tags:
        | index | oligo |
        | 1     | ACTG  |
        | 2     | GTCA  |

  @read @authorised
  Scenario: Reading the JSON for a UUID

    When I make an authorised GET of the API path "/11111111-2222-3333-4444-555555555555"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "lot_type": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "name": "Test Lot Type",
          "template_class": "TagLayoutTemplate",

          "uuid": "11111111-2222-3333-4444-555555555555"
        }
      }
      """


  @create @authorised @barcode-service
  Scenario: Creating a lot
    Given the UUID of the next lot created will be "00000000-1111-2222-3333-444444444444"
    And a user with UUID "99999999-8888-7777-6666-555555555555" exists

    When I make an authorised POST with the following JSON to the API path "/11111111-2222-3333-4444-555555555555/lots":
      """
      {
        "lot": {
          "lot_number": "1234567890",
          "user": "99999999-8888-7777-6666-555555555555",
          "received_at": "2014-02-01",
          "template": "00000000-1111-2222-3333-666666666666"
        }
      }
      """
    Then the HTTP response should be "201 Created"

    And the JSON should match the following for the specified fields:
      """
      {
        "lot": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "lot_type": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },
          "template": {
              "actions": {
                "read": "http://www.example.com/api/1/00000000-1111-2222-3333-666666666666"
              }
          },
          "qcables": {
            "size": 0,
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/qcables"
              }
          },

          "template_name": "Test tag layout",
          "lot_type_name": "Test Lot Type",
          "lot_number": "1234567890",
          "received_at": "2014-02-01",

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """

