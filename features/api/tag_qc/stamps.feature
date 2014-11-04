@api @json @single-sign-on @new-api
Feature: Access stamps through the API

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
    Given the lot exists with the attributes:
    | lot_number | lot_type      | received_at | template        |
    | 1234567890 | Test Lot Type | 2014-02-01  | Test tag layout |
    And the UUID for the lot with lot number "1234567890" is "00000000-1111-2222-3333-444444444444"


     Given the plate barcode webservice returns "1000001"
     And the plate barcode webservice returns "1000002"

     And lot "1234567890" has 2 created qcables
     And all qcables have sequential UUIDs based on "55555555-6666-7777-8888-00000000001"

     Given the UUID of the next stamp created will be "55555555-6666-7777-8888-000000000003"
     Given the UUID of the next robot created will be "55555555-6666-7777-8888-000000000004"
     And a robot exists

  @create @authorised @barcode-service
  Scenario: Creating a stamp
    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists


    When I make an authorised POST with the following JSON to the API path "/stamps":
      """
      {
        "stamp": {
          "tip_lot": "12345",
          "user":    "99999999-8888-7777-6666-555555555555",
          "robot":   "55555555-6666-7777-8888-000000000004",
          "lot":     "00000000-1111-2222-3333-444444444444",
          "stamp_details": [
            {"bed":"1", "order":2, "qcable":"55555555-6666-7777-8888-000000000011"},
            {"bed":"2", "order":1, "qcable":"55555555-6666-7777-8888-000000000012"}
          ]
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "stamp": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000003"
          },
          "qcables": {
            "size": 2,
            "actions": {
              "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000003/qcables"
            }
          },
          "user": {
            "actions": {
              "read": "http://www.example.com/api/1/99999999-8888-7777-6666-555555555555"
            }
          },
          "tip_lot": "12345"
        }
      }
      """
   And the qcables in lot "1234567890" should be "pending"

