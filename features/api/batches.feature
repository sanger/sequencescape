@api @json @batch @single-sign-on @new-api
Feature: Access batches through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual batches through their UUID
  And I want to be able to perform other operations to individual batches
  And I want to be able to do all of this only knowing the UUID of a batch
  And I understand I will never be able to delete a batch through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given I have a pipeline called "Testing the API"
    And the UUID for the pipeline "Testing the API" is "11111111-2222-3333-4444-555555555555"
    And the pipeline "Testing the API" accepts "Single ended sequencing" requests

  @read
  Scenario: Reading the JSON for a UUID
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline

    Given the user with login "John Smith" exists
    And "John Smith" is the owner of batch with ID 1

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "pipeline": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },
          "user": {
            "login": "John Smith"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "requests": [ ]
        }
      }
      """

  @read @authorised
  Scenario: Reading the JSON for a UUID when authorised
    Given the batch exists with ID 1
    And the UUID for the batch with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the last batch is for the "Testing the API" pipeline

    When I make an authorised GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "pipeline": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "requests": [ ]
        }
      }
      """
