@api @json @transfer @single-sign-on @new-api
Feature: Access transfers through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual transfers through their UUID
  And I want to be able to perform other operations to individual transfers
  And I want to be able to do all of this only knowing the UUID of a transfer
  And I understand I will never be able to delete a transfer through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a transfer between two plates
    Given the transfer between plates exists with ID 1
      And the UUID for the transfer between plates with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the UUID for the source of the transfer between plates with ID 1 is "11111111-2222-3333-4444-000000000001"
      And the UUID for the destination of the transfer between plates with ID 1 is "11111111-2222-3333-4444-000000000002"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "source": {
            "uuid": "11111111-2222-3333-4444-000000000001"
          },
          "destination": {
            "uuid": "11111111-2222-3333-4444-000000000002"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "transfers": {
            "A1": "A1",
            "B1": "B1"
          }
        }
      }
      """

  @read
  Scenario: Reading the JSON for a transfer from a plate to a tube
    Given the transfer from plate to tube exists with ID 1
      And the UUID for the transfer from plate to tube with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the UUID for the source of the transfer from plate to tube with ID 1 is "11111111-2222-3333-4444-000000000001"
      And the UUID for the destination of the transfer from plate to tube with ID 1 is "11111111-2222-3333-4444-000000000002"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "transfer": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "source": {
            "uuid": "11111111-2222-3333-4444-000000000001"
          },
          "destination": {
            "uuid": "11111111-2222-3333-4444-000000000002"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "transfers": [ "A1", "B1" ]
        }
      }
      """
