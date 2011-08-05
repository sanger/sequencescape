@api @json @project @single-sign-on @new-api
Feature: Access projects through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual projects through their UUID
  And I want to be able to perform other operations to individual projects
  And I want to be able to do all of this only knowing the UUID of a project
  And I understand I will never be able to delete a project through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @read
  Scenario: Reading the JSON for a UUID
    Given a project called "Testing the API" with ID 1
    Given the project "Testing the API" a budget division "Human variation"
    And the UUID for the project "Testing the API" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "project": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "name": "Testing the API",
          "project_manager": "Unallocated",
          "cost_code": "Some Cost Code",
          "funding_comments": null,
          "collaborators": null,
          "external_funding_source": null,
          "budget_division": "Human variation",
          "budget_cost_centre": null,
          "funding_model": null,

          "roles": {
          }
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """
