@api @json @multiplexed_library_tube @single-sign-on @new-api
Feature: Access multiplexed library tubes through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual multiplexed library tubes through their UUID
  And I want to be able to perform other operations to individual multiplexed library tubes
  And I want to be able to do all of this only knowing the UUID of a multiplexed library tube
  And I understand I will never be able to delete a multiplexed library tube through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @read
  Scenario: Reading the JSON for a UUID
    Given the multiplexed library tube exists with ID 1
      And the UUID for the multiplexed library tube with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "multiplexed_library_tube": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """
