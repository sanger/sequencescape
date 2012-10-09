@api @json @library_creation_request @single-sign-on @new-api
Feature: Access library creation requests through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual library creation requests through their UUID
  And I want to be able to perform other operations to individual library creation requests
  And I want to be able to do all of this only knowing the UUID of a library creation request
  And I understand I will never be able to delete a library creation request through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have a project called "My project"
    And the UUID for the project "My project" is "11111111-1111-2222-3333-444444444444"

    Given I have an active study called "Testing the sequencing requests API"
    And the UUID for the study "Testing the sequencing requests API" is "11111111-2222-3333-4444-000000000000"
    And I have a library tube of stuff called "tube_1"
    And the UUID for the library tube "tube_1" is "11111111-3333-4444-5555-666666666666"

  @read
  Scenario: Reading the JSON for a UUID
    Given I have already made a "Library creation" request with ID 1 within the study "Testing the sequencing requests API" for the project "My project"
    And the UUID for the library creation request with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "library_creation_request": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "type": "Library creation",
          "library_type": "Standard"
        }
      }
      """
