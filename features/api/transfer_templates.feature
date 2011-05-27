@api @json @transfer_template @single-sign-on @new-api
Feature: Access transfer templates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual transfer templates through their UUID
  And I want to be able to perform other operations to individual transfer templates
  And I want to be able to do all of this only knowing the UUID of a transfer template
  And I understand I will never be able to delete a transfer template through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @read
  Scenario: Reading the JSON for a UUID
    Given the transfer template called "Test transfers" exists
     And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "create": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Test transfers",
          "transfers": {
            "A1": "A1",
            "B1": "B1"
          }
        }
      }
      """

  @transfer @create
  Scenario: Creating a transfer from a transfer template
    Given the transfer template called "Test transfers" exists
      And the UUID for the transfer template "Test transfers" is "00000000-1111-2222-3333-444444444444"

    Given a transfer plate exists with ID 1
      And the UUID for the plate with ID 1 is "11111111-2222-3333-4444-000000000001"
      And a transfer plate exists with ID 2
      And the UUID for the plate with ID 2 is "11111111-2222-3333-4444-000000000002"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "transfer": {
          "source": "11111111-2222-3333-4444-000000000001",
          "destination": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "source": {
            "uuid": "11111111-2222-3333-4444-000000000001"
          },
          "destination": {
            "uuid": "11111111-2222-3333-4444-000000000002"
          },
          "transfers": {
            "A1": "A1",
            "B1": "B1"
          }
        }
      }
      """

    Then the transfers from plate 1 to plate 2 should be:
      | source | destination |
      | A1     | A1          |
      | B1     | B1          |

