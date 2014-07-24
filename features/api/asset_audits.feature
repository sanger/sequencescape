@api @json @asset_audit @single-sign-on @new-api
Feature: Access asset audits through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual asset audits through their UUID
  And I want to be able to perform other operations to individual asset audits
  And I want to be able to do all of this only knowing the UUID of a asset audit
  And I understand I will never be able to delete a asset audit through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @create @error
  Scenario: Creating a asset audit without passing in an asset
    Given the UUID of the next asset audit created will be "00000000-1111-2222-3333-444444444444"
    When I make an authorised POST with the following JSON to the API path "/asset_audits":
      """
      {
        "asset_audit": {
          "message": "My message",
          "key": "some_key",
          "created_by": "john",
          "witnessed_by": "jane"
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "asset": ["can't be blank"]
        }
      }
      """

  @create @error
  Scenario: Creating a asset audit without passing in a key
    Given the plate exists with ID 1
    And the UUID for the plate with ID 1 is "00000000-1111-2222-3333-555555555555"
    Given the UUID of the next asset audit created will be "00000000-1111-2222-3333-444444444444"
    When I make an authorised POST with the following JSON to the API path "/asset_audits":
      """
      {
        "asset_audit": {
          "message": "My message",
          "created_by": "john",
          "asset": "00000000-1111-2222-3333-555555555555"

        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "key": ["can't be blank", "Key can only contain letters, numbers or _"]
        }
      }
      """

  @create @error
  Scenario Outline: Creating a asset audit with an invalid key
    Given the plate exists with ID 1
    And the UUID for the plate with ID 1 is "00000000-1111-2222-3333-555555555555"
    Given the UUID of the next asset audit created will be "00000000-1111-2222-3333-444444444444"
    When I make an authorised POST with the following JSON to the API path "/asset_audits":
      """
      {
        "asset_audit": {
          "message": "My message",
          "created_by": "john",
          "key": "<key>",
          "asset": "00000000-1111-2222-3333-555555555555"

        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "key": ["Key can only contain letters, numbers or _"]
        }
      }
      """
    Examples:
    | key     |
    | abc abc |
    | a-b     |
    | *       |


  @create
  Scenario: Creating a asset audit
    Given the plate exists with ID 1
    And the UUID for the plate with ID 1 is "00000000-1111-2222-3333-555555555555"
    Given the UUID of the next asset audit created will be "00000000-1111-2222-3333-444444444444"
    When I make an authorised POST with the following JSON to the API path "/asset_audits":
      """
      {
        "asset_audit": {
          "message": "My message",
          "key": "some_key",
          "created_by": "john",
          "asset": "00000000-1111-2222-3333-555555555555",
          "witnessed_by": "jane"

        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "asset_audit": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "uuid": "00000000-1111-2222-3333-444444444444",
          "created_by": "john",
          "key": "some_key",
          "message": "My message",
          "witnessed_by": "jane",

          "asset": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-555555555555"
            },
            "uuid": "00000000-1111-2222-3333-555555555555"
          }
        }
      }
      """
    Given I am logged in as "user"
      And I am on the events page for asset 1
    Then the activity logging table should be:
      | Message    | Key      | Created by | Created at             |
      | My message | some_key | john       | October 23, 2010 23:00 |

  @read
  Scenario: Reading the JSON for a UUID
    Given the asset audit exists with ID 1
    And the UUID for the asset audit with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "asset_audit": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "created_by": "abc123",
          "key": "some_key",
          "message": "Some message",
          "witnessed_by": "jane",

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """
