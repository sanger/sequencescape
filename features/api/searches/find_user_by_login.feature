@api @json @user @search @single-sign-on @new-api
Feature: Searching for users by login
  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given the UUID for the search "Find user by login" is "00000000-1111-2222-3333-444444444444"

  @single
    Scenario: looking for an existing user by login
      Given user "user_login" exists
      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "login": "user_login"
        }
      }
      """
    Then the HTTP response should be "301 Moved permanently"
    And the JSON should match the following for the specified fields:
    """
        {
          "user":{
            "login":"user_login",
            "first_name":"User Login",
            "email":"user_login@example.com"
          }
        }
    """
  @multiple
    Scenario: looking for many existing users by login
      Given user "user_login" exists
      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
      """
      {
        "search": {
          "login": "user_login"
        }
      }
      """
    Then the HTTP response should be "300 Multiple Content"
     And the JSON should match the following for the specified fields:
    """
        {
          "searches": [
          {
            "login":"user_login",
            "first_name":"User Login",
            "email":"user_login@example.com"
          }
          ]
        }
    """
    @error
  Scenario: looking for a non-existing login
      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "login": "user_login"
        }
      }
      """
    Then the HTTP response should be "404 Not Found"


