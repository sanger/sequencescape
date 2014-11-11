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
    Given I have a qcable

  @read @authorised @barcode-service
  Scenario: Plates Should Inherit state form their qcable
    When I make an authorised GET of the API path "/55555555-6666-7777-8888-000000000004"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000004"
          },
          "state": "created"
        }
      }
      """
  @create @read @authorised
  Scenario: Plates should update their state on state change
    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists
    And all qcables in lot "1234567890" are "available"
    Given the UUID of the next state change created will be "55555555-6666-7777-8888-000000000003"
    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "55555555-6666-7777-8888-000000000004",
          "target_state": "destroyed",
          "reason": "testing this works"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "state_change": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000003"
          },
          "target": {
            "actions": {
              "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000004"
            }
          },
          "target_state": "destroyed",
          "previous_state": "available",
          "reason": "testing this works"
        }
      }
      """
      And the qcables in lot "1234567890" should be "destroyed"
