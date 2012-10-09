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

  @read
  Scenario: Reading the JSON for a user UUID
    Given the user exists with ID 1 and the following attributes:
      | name       | value            |
      | login      | user_login       |
      | email      | user@example.com |
      | first_name | John             |
      | last_name  | Smith            |

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
          "first_name": "John",
          "last_name": "Smith",
          "has_a_swipecard_code": false,

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """
      And the JSON should not contain "update" within any element of "user.actions"

  Scenario: Reading the JSON for a user UUID with an authorised application
    Given the user exists with ID 1 and the following attributes:
      | name       | value            |
      | login      | user_login       |
      | email      | user@example.com |
      | first_name | John             |
      | last_name  | Smith            |

    And the UUID for the user with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I make an authorised GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "user": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          }
      }
      """

  Scenario: Updating the JSON for a user UUID from an unauthorised application
    Given the user exists with ID 1 and the following attributes:
      | name       | value            |
      | login      | user_login       |
      | email      | user@example.com |
      | first_name | John             |
      | last_name  | Smith            |

    And the UUID for the user with ID 1 is "00000000-1111-2222-3333-444444444444"
    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
       """
       {
         "user": {
            "email": "new_email@example.com",
            "first_name": "Jack",
            "last_name": "Smooth",
            "swipecard_code": "my code"
         }
       }
       """
    Then the HTTP response should be "501"
    And the JSON should match the following for the specified fields:
    """
    {
      "general":[ "requested action is not supported on this resource"]
    }
    """

  Scenario: Updating the JSON for a user UUID
    Given the user exists with ID 1 and the following attributes:
      | name       | value            |
      | login      | user_login       |
      | email      | user@example.com |
      | first_name | John             |
      | last_name  | Smith            |

    And the UUID for the user with ID 1 is "00000000-1111-2222-3333-444444444444"
    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
       """
       {
         "user": {
            "email": "new_email@example.com",
            "first_name": "Jack",
            "last_name": "Smooth",
            "swipecard_code": "my code"
         }
       }
       """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "user": {
          "login": "user_login",
          "email": "new_email@example.com",
          "first_name": "Jack",
          "last_name": "Smooth",
          "has_a_swipecard_code": true,
          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """
