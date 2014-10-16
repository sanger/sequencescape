@api @json @reference_genome @single-sign-on @new-api
Feature: Access reference genomes through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual reference genomes through their UUID
  And I want to be able to perform other operations to individual reference genomes
  And I want to be able to do all of this only knowing the UUID of a reference genome
  And I understand I will never be able to delete a reference genome through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @create
  Scenario: Creating a reference genome
    Given the UUID of the next reference genome created will be "00000000-1111-2222-3333-444444444444"
    And a user with an api key of "I-am-authenticated" exists
    When I make an authorised POST with the following JSON to the API path "/reference_genomes":
      """
      {"reference_genome": { "name": "testing-of-creation"}}
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "reference_genome": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "name": "testing-of-creation",
          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """

  @create @error
  Scenario: Creating a reference genome which results in an error
    Given a reference genome called "testing-of-creation" with UUID "00000000-1111-2222-3333-444444444444"
    When I make an authorised POST with the following JSON to the API path "/reference_genomes":
      """
      {"reference_genome": { "name": "testing-of-creation"}}
      """
    Then the HTTP response should be "422 Unprocessable Entity"
     And the JSON should be:
      """
      {
        "content": {
          "name": ["of reference genome already present in database"]
        }
      }
      """

  @read
  Scenario: Reading the JSON for a reference genome UUID
   Given a reference genome called "testing-of-reading" with UUID "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "reference_genome": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "name": "testing-of-reading",
          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """

  @read
  Scenario: Updating the JSON for a reference genome UUID
    Given a reference genome called "testing-of-reading" with UUID "00000000-1111-2222-3333-444444444444"

    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {"reference_genome": { "name": "testing-of-update"}}
      """
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "reference_genome": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "name": "testing-of-update",
          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """
