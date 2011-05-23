@api @user @swipcard @single-sign-on
Feature: Set and check swipcard code of users through the API
  In order to allow users to use their swipcard to authenticate
  As an authenticated user of the API
  I want to be able to set the swipcard code of users which haven't one

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  Scenario: Set a swipcard code to a user
    Given the user exists with ID 1
    And the UUID for the user with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
       """
       {
         "user": {
            "swipcard_code": "swip"
         }
       }
       """
    Then the HTTP response should be "200 OK"
    And the user 1 should validate the swipcard code "swip"
