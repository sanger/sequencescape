@api @json @state_change @single-sign-on @new-api
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

    Given a "Stock plate" plate called "Source plate" exists
      And a "Stock plate" plate called "Destination plate" exists
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
          "target": "00000000-1111-2222-3333-000000000002",
          "target_state": "<state>"
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
          "previous_state": "pending"
        }
      }
      """

    Then the state of the plate "Destination plate" should be "<state>"
     And the state of all the transfer requests to the plate "Destination plate" should be "<state>"

    Scenarios:
      | state   |
      | pending |
      | started |
      | passed  |
      | failed  |

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
