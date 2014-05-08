@api @json @project @allow-rescue
Feature: Interacting with projects through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the projects that exist if there aren't any
    When I GET the API path "/projects"
    Then the JSON should be an empty array

  Scenario: Listing all of the projects that exist
    Given the pathogen project called "Testing the JSON API" exists
    And project "Testing the JSON API" has an owner called "abc123"
    And the UUID for the project "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/projects"
    Then ignoring "updated_at|id" the JSON should be:
      """
      [
        {
            "project": {
                "name": "Testing the JSON API",
                "created_at": "2010-09-16T13:45:00+01:00",
                "collaborators": "No collaborators",
                "funding_comments": "External funding",
                "uuid": "00000000-1111-2222-3333-444444444444",

                "approved": true,
                "funding_model": "Internal",
                "budget_cost_centre": "Sanger",
                "external_funding_source": "EU",
                "budget_division": "Pathogen (including malaria)",
                "project_manager": "Unallocated",
                "cost_code": "ABC",
                "owner": [{"email": "abc123@example.com",
                    "login": "abc123",
                    "name": "John Doe"
                }],
                "state": "active",

                "id": 644
            }
        }
      ]
      """

  Scenario: Retrieving the JSON for a project that does not exist
    When I GET the API path "/projects/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular project
    Given the pathogen project called "Testing the JSON API" exists
    And project "Testing the JSON API" has an owner called "abc123"
    And the UUID for the project "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    When I GET the API path "/projects/00000000-1111-2222-3333-444444444444"
    Then ignoring "updated_at|id" the JSON should be:
      """
      {
          "project": {
              "name": "Testing the JSON API",
              "created_at": "2010-09-16T13:45:00+01:00",
              "collaborators": "No collaborators",
              "funding_comments": "External funding",
              "uuid": "00000000-1111-2222-3333-444444444444",

              "approved": true,
              "funding_model": "Internal",
              "budget_cost_centre": "Sanger",
              "external_funding_source": "EU",
              "budget_division": "Pathogen (including malaria)",
              "project_manager": "Unallocated",
              "cost_code": "ABC",
              "owner": [{"email": "abc123@example.com",
                  "login": "abc123",
                  "name": "John Doe"
              }],
              "state": "active",

              "id": 644
          }
      }
      """
