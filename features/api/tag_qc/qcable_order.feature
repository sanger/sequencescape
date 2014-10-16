@api @json @single-sign-on @new-api @barcode-service
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
    Given the lot exists with the attributes:
    | lot_number | lot_type      | received_at | template        |
    | 1234567890 | Test Lot Type | 2014-02-01  | Test tag layout |
    And the UUID for the lot with lot number "1234567890" is "00000000-1111-2222-3333-444444444444"

    Given I am set up for testing qcable ordering

  @read @authorised
  Scenario: The lots should be sorted properly

    Given the number of results returned by the API per page is 6
    When I make an authorised GET of the API path "/00000000-1111-2222-3333-444444444444/qcables"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "actions": {
          "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/qcables/1",
          "first": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/qcables/1",
          "last": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/qcables/1"
        },
        "size": 6,
        "qcables": [
          {
            "updated_at": "2010-10-23 23:00:00 +0100",
            "barcode": {"number": "1000001", "prefix": "DN"},
            "state": "pending",
            "stamp_index": 0,
            "stamp_bed": "1"
          },
          {
            "barcode": {"number": "1000002", "prefix": "DN"},
            "state": "created",
            "stamp_index": null,
            "stamp_bed": null
          },
          {
            "updated_at": "2010-10-23 23:20:00 +0100",
            "barcode": {"number": "1000003", "prefix": "DN"},
            "state": "pending",
            "stamp_index": 3,
            "stamp_bed": "3"
          },
          {
            "updated_at": "2010-10-23 23:20:00 +0100",
            "barcode": {"number": "1000004", "prefix": "DN"},
            "state": "pending",
            "stamp_index": 2,
            "stamp_bed": "5"
          },
          {
            "updated_at": "2010-10-23 23:00:00 +0100",
            "barcode": {"number": "1000005", "prefix": "DN"},
            "state": "pending",
            "stamp_index": 1,
            "stamp_bed": "2"
          },
          {
            "barcode": {"number": "1000006", "prefix": "DN"},
            "state": "created",
            "stamp_index": null,
            "stamp_bed": null
          }
      ]
    }
      """
