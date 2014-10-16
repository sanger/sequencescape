@api @json @user @search @single-sign-on @new-api
Feature: Searching for lots by lot number
  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given the UUID for the search "Find lot by lot number" is "00000000-1111-2222-3333-444444444444"

  @single
    Scenario: looking for an existing user by swipecard code
    Given I have a lot type for testing called "Test Lot Type"
      And the tag layout template "Test tag layout" exists
      And the lot exists with the attributes:
    | lot_number | lot_type      | received_at | template        |
    | 1234567890 | Test Lot Type | 2014-02-01  | Test tag layout |
      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "lot_number": "1234567890"
        }
      }
      """
    Then the HTTP response should be "301 Moved permanently"
    And the JSON should match the following for the specified fields:
    """
        {
          "lot":{
            "lot_number":"1234567890",
            "template_name":"Test tag layout"
          }
        }
    """
