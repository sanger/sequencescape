@api @json @request_type @single-sign-on @new-api
Feature: Access request types through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual request types through their UUID
  And I want to be able to perform other operations to individual request types
  And I want to be able to do all of this only knowing the UUID of a request type
  And I understand I will never be able to delete a request type through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given no request types exist

  @read
  Scenario: Reading the JSON for a UUID
    Given the request type "Sequencing by colour" exists
    And the UUID for the request type "Sequencing by colour" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "request_type": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Sequencing by colour"
        }
      }
      """
