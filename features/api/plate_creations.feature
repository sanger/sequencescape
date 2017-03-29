@api @json @plate_creation @single-sign-on @new-api @barcode-service
Feature: Access plate creations through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual plate creations through their UUID
  And I want to be able to perform other operations to individual plate creations
  And I want to be able to do all of this only knowing the UUID of a plate creation
  And I understand I will never be able to delete a plate creation through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given a plate purpose called "Parent plate purpose" with UUID "11111111-2222-3333-4444-000000000001"
      And a plate purpose called "Child plate purpose" with UUID "11111111-2222-3333-4444-000000000002"
      And the plate purpose "Parent plate purpose" is a parent of the plate purpose "Child plate purpose"

    Given a "Parent plate purpose" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"

  @create
  Scenario: Creating a plate creation
    Given the UUID of the next plate creation created will be "55555555-6666-7777-8888-000000000001"
      And the UUID of the next plate created will be "00000000-1111-2222-3333-000000000002"

    When I make an authorised POST with the following JSON to the API path "/plate_creations":
      """
      {
        "plate_creation": {
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
        "plate_creation": {
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

    Then the child plate of the last plate creation is a child of the parent plate

  @create @error
  Scenario Outline: Creating a plate creation which results in an error
    When I make an authorised POST with the following JSON to the API path "/plate_creations":
      """
      {
        "plate_creation": {
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
    Given the plate creation exists with ID 1
      And the UUID for the plate creation with ID 1 is "55555555-6666-7777-8888-000000000001"
      And the UUID for the parent plate of the plate creation with ID 1 is "00000000-1111-2222-3333-000000000001"
      And the UUID for the child plate of the plate creation with ID 1 is "00000000-1111-2222-3333-000000000002"
      And the UUID for the child plate purpose of the plate creation with ID 1 is "11111111-2222-3333-4444-000000000002"

    When I GET the API path "/55555555-6666-7777-8888-000000000001"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate_creation": {
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
