@api @json @user @search @single-sign-on @new-api
Feature: Searching for users by swipecard code
  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given the UUID for the search "Find user by swipecard code" is "00000000-1111-2222-3333-444444444444"

  @single
    Scenario: looking for an existing user by swipecard code
    Given the user exists with ID 1 and the following attributes:
      | name | value |
      | first_name | me |
      | swipecard_code | code |
      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "swipecard_code": "code"
        }
      }
      """
    Then the HTTP response should be "301 Moved permanently"
    And the JSON should match the following for the specified fields:
    """
        {
          "user":{
            "first_name":"me"
          }
        }
    """
