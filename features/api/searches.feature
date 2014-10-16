@api @json @search @single-sign-on @new-api
Feature: Access searches through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual searches through their UUID
  And I want to be able to perform other operations to individual searches
  And I want to be able to do all of this only knowing the UUID of a search
  And I understand I will never be able to delete a search through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given the UUID for the search "Find assets by barcode" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "search": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "first": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/first",
            "last": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/last",
            "all": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/all"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Find assets by barcode"
        }
      }
      """
