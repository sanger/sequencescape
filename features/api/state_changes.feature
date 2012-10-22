@api @json @state_change @single-sign-on @new-api @barcode-service
Feature: Access state changes through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual state changes through their UUID
  And I want to be able to perform other operations to individual state changes
  And I want to be able to do all of this only knowing the UUID of a state change
  And I understand I will never be able to delete a state change through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given transfers between "Stock plate" and "Pulldown QC plate" plates are done by "Transfer" requests

    Given a "Stock plate" plate called "Source plate" exists
      And all wells on the plate "Source plate" have unique samples
      And a "Pulldown QC plate" plate called "Destination plate" exists as a child of "Source plate"
      And the UUID for the plate "Source plate" is "00000000-1111-2222-3333-000000000001"
      And the UUID for the plate "Destination plate" is "00000000-1111-2222-3333-000000000002"
      And the "Transfer columns 1-12" transfer template has been used between "Source plate" and "Destination plate"

  @create
  Scenario Outline: Creating a state change on a plate
    Given the UUID of the next state change created will be "11111111-2222-3333-4444-000000000001"

    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-000000000002",
          "target_state": "<state>",
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
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
          },
          "target": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "target_state": "<state>",
          "previous_state": "pending",
          "reason": "testing this works"
        }
      }
      """

    Then the state of the plate "Destination plate" should be "<state>"
     And the state of all the transfer requests to the plate "Destination plate" should be "<state>"
     And the request type of all the transfer requests to the the plate "Destination plate" should be "Transfer"
     #And the state of all the pulldown library creation requests from the plate "Source plate" should be "<library state>"

    Scenarios:
      | state     | 
      | pending   | 
      | started   | 
      | passed    | 
      | failed    | 

  @create
  Scenario Outline: Creating a state change on a plate where the state requires a reason
    Given the UUID of the next state change created will be "11111111-2222-3333-4444-000000000001"

    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-000000000002",
          "target_state": "<state>"
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
     And the JSON should match the following for the specified fields:
      """
      {
        "content": {
          "reason": [ "can't be blank" ]
        }
      }
      """

    Scenarios:
      | state     | 
      | failed    | 
      | cancelled | 

  @create
  Scenario: Changing the state of only one well on the plate
    Given the UUID of the next state change created will be "11111111-2222-3333-4444-000000000001"

    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-000000000002",
          "contents": [ "A1" ],
          "target_state": "failed",
          "reason": "testing this"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "state_change": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
          },
          "target": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "target_state": "failed",
          "contents": [ "A1" ],
          "previous_state": "pending",
          "reason": "testing this"
        }
      }
      """

    Then the state of the plate "Destination plate" should be "pending"
     And the state of transfer requests to "A1-A1" on the plate "Destination plate" should be "failed"
     And the state of transfer requests to "A2-H12" on the plate "Destination plate" should be "pending"

  @read @wip
  Scenario: Reading the JSON for a UUID
    Given the state change exists with ID 1
      And the UUID for the state change with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "state_change": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """

  @create
  Scenario: Changing the state of only one well on the plate with pulldown requests
    Given the UUID of the next state change created will be "11111111-2222-3333-4444-000000000001"
      And "A1-H12" of the plate "Source plate" have been submitted to "Pulldown WGS - HiSeq paired end sequencing"
      And all requests are in the last submission
      And all the "Pulldown::Requests::WgsLibraryRequest" requests in the last submission have been started
    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-000000000002",
          "contents": [ "A1" ],
          "target_state": "failed",
          "reason": "testing this"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "state_change": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
          },
          "target": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "target_state": "failed",
          "contents": [ "A1" ],
          "previous_state": "pending",
          "reason": "testing this"
        }
      }
      """

    Then the state of the plate "Destination plate" should be "pending"
     And the state of transfer requests to "A1-A1" on the plate "Destination plate" should be "failed"
     And the state of transfer requests to "A2-H12" on the plate "Destination plate" should be "pending"
     And the state of pulldown library creation requests from "A1-A1" on the plate "Source plate" should be "failed"
     And the state of pulldown library creation requests from "A2-H12" on the plate "Source plate" should be "started"

  @create
  Scenario Outline: Creating a state change on a plate with pulldown requests
    Given the UUID of the next state change created will be "11111111-2222-3333-4444-000000000001"
      And "A1-H12" of the plate "Source plate" have been submitted to "Pulldown WGS - HiSeq paired end sequencing"
      And all requests are in the last submission

    When I make an authorised POST with the following JSON to the API path "/state_changes":
      """
      {
        "state_change": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-000000000002",
          "target_state": "<state>",
          "reason": "testing this"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "state_change": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000001"
          },
          "target": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "target_state": "<state>",
          "previous_state": "pending",
          "reason": "testing this"
        }
      }
      """

    Then the state of the plate "Destination plate" should be "<state>"
     And the state of all the transfer requests to the plate "Destination plate" should be "<state>"
     And the state of all the pulldown library creation requests from the plate "Source plate" should be "<library state>"

    Scenarios:
      | state     | library state | 
      | pending   | pending       | 
      | started   | pending       | 
      | passed    | pending       | 

    Scenarios:
      | state   | library state |
      | failed  | failed        |
