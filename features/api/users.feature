@api @json @user @single-sign-on @new-api
Feature: Access users through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual users through their UUID
  And I want to be able to perform other operations to individual users
  And I want to be able to do all of this only knowing the UUID of a user
  And I understand I will never be able to delete a user through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @read @error
  Scenario: Reading the JSON for a user UUID that does not exist
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "UUID does not exist" ]
      }
      """

  @read
  Scenario: Reading the JSON for a user UUID
    Given the user exists with ID 1 with the following attributes:
      | name | value |
      | login | user_login |
      | email | user@example.com |

    And the UUID for the user with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "user": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "login": "user_login",
          "email": "user@example.com",

          "uuid": "00000000-1111-2222-3333-444444444444"
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """
