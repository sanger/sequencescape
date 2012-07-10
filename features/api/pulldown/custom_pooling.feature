@api @json @single-sign-on @new-api
Feature: Custom pooling within the pulldown pipeline
  During the ISC pulldown pipeline there is a stage were custom pooling is required.  The pooling is
  initially based on the submissions, done using a preview, but is then governed by the lab tech who
  may pool things differently because of the chemistry involved.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the UUID for the transfer template "Custom pooling" is "00000000-1111-2222-3333-444444444444"

    Given a source transfer plate called "Source plate" exists
      And the UUID for the plate "Source plate" is "11111111-2222-3333-4444-000000000001"
      And a destination transfer plate called "Destination plate" exists
      And the UUID for the plate "Destination plate" is "11111111-2222-3333-4444-000000000002"

  Scenario: Pooling is based on the transfers from the client
    When I make an authorised POST with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "transfer": {
          "user": "99999999-8888-7777-6666-555555555555",
          "source": "11111111-2222-3333-4444-000000000001",
          "destination": "11111111-2222-3333-4444-000000000002",
          "transfers": {
            "A1": "B1",
            "B1": "A1"
          }
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
            "A1": "B1",
            "B1": "A1"
          }
        }
      }
      """

    Then the transfers from the plate "Source plate" to the plate "Destination plate" should be:
      | source | destination |
      | A1     | B1          |
      | B1     | A1          |
