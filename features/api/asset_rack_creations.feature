@api @json @asset_rack_creation @single-sign-on @new-api @barcode-service
Feature: Access rack creations through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual rack creations through their UUID
  And I want to be able to perform other operations to individual rack creations
  And I want to be able to do all of this only knowing the UUID of a rack creation
  And I understand I will never be able to delete a rack creation through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given the UUID for the plate purpose "Cherrypicked" is "11111111-2222-3333-4444-000000000001"
      And an asset rack purpose called "Asset rack purpose" with UUID "11111111-2222-3333-4444-000000000002"
      And the purpose "Cherrypicked" is a parent of the purpose "Asset rack purpose"


    Given a "Cherrypicked" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"

  @create
  Scenario: Creating a rack creation
    Given the UUID of the next asset rack creation created will be "55555555-6666-7777-8888-000000000001"
      And the UUID of the next asset rack created will be "00000000-1111-2222-3333-000000000002"

    When I make an authorised POST with the following JSON to the API path "/asset_rack_creations":
      """
      {
        "asset_rack_creation": {
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
        "asset_rack_creation": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000001"
          },
          "parent": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000001"
            }
          },
          "child": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "child_purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000002"
            }
          },

          "uuid": "55555555-6666-7777-8888-000000000001"
        }
      }
      """

    Then the child asset rack of the last asset rack creation is a child of the parent plate
    And the last asset rack has a strip tube in position 2 named "DN1000001M:S02"

  @create @error
  Scenario Outline: Creating a asset rack creation which results in an error
    When I make an authorised POST with the following JSON to the API path "/asset_rack_creations":
      """
      {
        "asset_rack_creation": {
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
      | "user": "99999999-8888-7777-6666-555555555555", "parent": "00000000-1111-2222-3333-000000000001", "child_purpose": "11111111-2222-3333-4444-000000000001" | "child_purpose": [ "is not a valid child type" ] |

  @read
  Scenario: Reading the JSON for a UUID
    Given a plate purpose called "Parent plate purpose" with UUID "11111111-2222-3333-4444-000000000001"
      And the purpose "Parent plate purpose" is a parent of the purpose "Asset rack purpose"
    Given the asset rack creation exists with ID 1
      And the UUID for the asset rack creation with ID 1 is "55555555-6666-7777-8888-000000000001"
      And the UUID for the parent plate of the asset rack creation with ID 1 is "00000000-1111-2222-3333-000000000001"
      And the UUID for the child asset rack of the asset rack creation with ID 1 is "00000000-1111-2222-3333-000000000002"
      And the UUID for the child asset rack purpose of the asset rack creation with ID 1 is "11111111-2222-3333-4444-000000000002"

    When I GET the API path "/55555555-6666-7777-8888-000000000001"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "asset_rack_creation": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000001"
          },
          "parent": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000001"
            }
          },
          "child": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "child_purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000002"
            }
          },

          "uuid": "55555555-6666-7777-8888-000000000001"
        }
      }
      """
