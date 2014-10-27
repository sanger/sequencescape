@api @json @asset @search @single-sign-on @new-api @barcode_search
Feature: Searching for robots by barcode
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @search_assets @single
  Scenario: Looking up a single robot by barcode
    Given the UUID for the search "Find robot by barcode" is "00000000-1111-2222-3333-444444444444"

    Given a robot exists with barcode "3"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "barcode": 4880000003807
        }
      }
      """
    Then the HTTP response should be "301 Moved Permanently"
     And the JSON should match the following for the specified fields:
      """
      {
        "robot": {
          "name": "myrobot"
        }
      }
      """


  @single @sample_tube @error
  Scenario: Looking up with a bed barcode should fail
    Given the UUID for the search "Find robot by barcode" is "00000000-1111-2222-3333-444444444444"

    Given a robot exists with barcode "3"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "barcode": 580000003824
        }
      }
      """
    Then the HTTP response should be "404 Not Found"
     And the JSON should be:
      """
      { "general": [ "no resources found with that search criteria" ] }
      """

