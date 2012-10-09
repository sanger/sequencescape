@api @json @study @single-sign-on @new-api @study_api
Feature: Access studies through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual studies through their UUID
  And I want to be able to perform other operations to individual studies
  And I want to be able to do all of this only knowing the UUID of a study
  And I understand I will never be able to delete a study through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @read
  Scenario: Reading the JSON for a UUID
    Given a study called "Testing the API" with ID 1
    And the UUID for the study "Testing the API" is "00000000-1111-2222-3333-444444444444"
    And the faculty sponsor for study "Testing the API" is "John Smith"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "study": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Testing the API",

          "ethically_approved": false,
          "state": "pending",
          "abbreviation": "WTCCC",

          "type": "Not specified",
          "sac_sponsor": "John Smith",
          "reference_genome": null,
          "accession_number": null,
          "description": "Some study on something",
          "abstract": null,

          "contaminated_human_dna": "No",
          "contains_human_dna": "No",
          "remove_x_and_autosomes": false,
          "commercially_available": "No",
          "data_release_sort_of_study": "genomic sequencing",
          "data_release_strategy": "open",
          "reference_genome": "",

          "samples": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/samples"
            }
          },
          "projects": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/projects"
            }
          },
          "asset_groups": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/asset_groups"
            }
          },
          "sample_manifests": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_manifests",
              "create_for_plates": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_manifests/create_for_plates",
              "create_for_tubes": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_manifests/create_for_tubes"
            }
          }
        }
      }
      """
