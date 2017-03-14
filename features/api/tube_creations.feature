@api @json @tube_creation @single-sign-on @new-api @barcode-service
Feature: Access creation creations through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual tube creations through their UUID
  And I want to be able to perform other operations to individual tube creations
  And I want to be able to do all of this only knowing the UUID of a tube creation
  And I understand I will never be able to delete a tube creation through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given a plate purpose called "Parent plate purpose" with UUID "11111111-2222-3333-4444-000000000001"
      And a tube purpose called "Child tube purpose" with UUID "11111111-2222-3333-4444-000000000002"
      And the purpose "Parent plate purpose" is a parent of the purpose "Child tube purpose"

    Given a "Parent plate purpose" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"
      And the plate "Testing the API" will pool into 1 tube

  # NOTE: we cannot predefine the ID here so we ignore it in the uuids_to_ids map
  @create
  Scenario: Creating a tube creation
    Given the UUID of the next tube creation created will be "55555555-6666-7777-8888-000000000001"
      And the UUID of the next multiplexed library tube created will be "00000000-1111-2222-3333-000000000002"

    When I make an authorised POST with the following JSON to the API path "/tube_creations":
      """
      {
        "tube_creation": {
          "user": "99999999-8888-7777-6666-555555555555",
          "parent": "00000000-1111-2222-3333-000000000001",
          "child_purpose": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "tube_creation": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000001"
          },
          "parent": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000001"
            }
          },
          "child_purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000002"
            }
          },
          "children": {
            "actions": {
              "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000001/children"
            },
            "size": 1
          },

          "uuid": "55555555-6666-7777-8888-000000000001"
        }
      }
      """

    Then the tubes of the last tube creation are children of the parent plate

  @create @error
  Scenario Outline: Creating a tube creation which results in an error
    When I make an authorised POST with the following JSON to the API path "/tube_creation":
      """
      {
        "tube_creation": {
          <json>
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
     And the JSON should be:
      """
      {
        "content": {
          <error>
        }
      }
      """

    Scenarios:
      | json                                                                                                                                                      | error                                            |
      | "parent": "00000000-1111-2222-3333-000000000001", "child_purpose": "11111111-2222-3333-4444-000000000002"                                                 | "user": [ "can't be blank" ]                     |
      | "user": "99999999-8888-7777-6666-555555555555", "parent": "00000000-1111-2222-3333-000000000001"                                                          | "child_purpose": [ "can't be blank" ]            |
      | "user": "99999999-8888-7777-6666-555555555555", "child_purpose": "11111111-2222-3333-4444-000000000002"                                                   | "parent": [ "can't be blank" ]                   |

  @read
  Scenario: Reading the JSON for a UUID
    Given the tube creation exists with ID 1
      And the UUID for the tube creation with ID 1 is "55555555-6666-7777-8888-000000000001"
      And the UUID for the parent plate of the tube creation with ID 1 is "00000000-1111-2222-3333-000000000001"
      And the UUID for the child tube of the tube creation with ID 1 is "00000000-1111-2222-3333-000000000002"
      And the UUID for the child tube purpose of the tube creation with ID 1 is "11111111-2222-3333-4444-000000000002"

    When I GET the API path "/55555555-6666-7777-8888-000000000001"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "tube_creation": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000001"
          },
          "parent": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000001"
            }
          },
          "child_purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000002"
            }
          },
          "children": {
            "actions": {
              "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000001/children"
            },
            "size": 2
          },

          "uuid": "55555555-6666-7777-8888-000000000001"
        }
      }
      """
