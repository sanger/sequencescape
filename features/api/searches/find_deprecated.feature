@api @json @asset @search @single-sign-on @new-api @barcode_search
Feature: Searching for assets with a deprecated search
  Background:
    Given all of this is happening at exactly "12-Jun-2012 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

    Given the UUID for the search "Find pulldown plates" is "00000000-1111-2222-3333-444444444444"

    Scenario: I should see a deprecation warning
      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
        """
        {
          "search": {
            "state": ["pending","started","failed","passed"]
          }
        }
        """

        Then the HTTP response should be "410 Gone"
         And the JSON should match the following for the specified fields:
          """
            {"general": ["requested action is no longer supported"]}
          """
