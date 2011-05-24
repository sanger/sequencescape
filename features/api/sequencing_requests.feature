@api @json @sequencing_request @single-sign-on @new-api
Feature: Access sequencing requests through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual sequencing requests through their UUID
  And I want to be able to perform other operations to individual sequencing requests
  And I want to be able to do all of this only knowing the UUID of a sequencing request
  And I understand I will never be able to delete a sequencing request through its UUID

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

  @read @error
  Scenario: Reading the JSON for a UUID that does not exist
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "UUID does not exist" ]
      }
      """

  @read
  Scenario: Reading the JSON for a UUID
    Given I have already made a "Paired end sequencing" request with ID 1 within the study "Testing the sequencing requests API" for the project "My project"
    And the UUID for the sequencing request with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sequencing_request": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "type": "Paired end sequencing",
          "read_length": 76
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """
