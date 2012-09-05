@api @json @study @allow-rescue @study_api
Feature: Interacting with studies through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the studies that exist if there aren't any
    When I GET the API path "/studies"
    Then the JSON should be an empty array

  Scenario: Listing all of the studies that exist
    Given I have an active study called "Testing the JSON API"
    And the UUID for the study "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And the faculty sponsor for study "Testing the JSON API" is "John Smith"
    And the Array Express accession number for study "Testing the JSON API" is "AE111"
    And the EGA policy accession number for study "Testing the JSON API" is "EGA222"
    And the dac accession number for study "Testing the JSON API" is "DAC333"

    When I GET the API path "/studies"
    Then ignoring "updated_at|id" the JSON should be:
      """
      [
        {
          "study": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "name": "Testing the JSON API",
            "ethically_approved": false,
            "reference_genome": "",
            "study_type": "Not specified",
            "abstract": null,
            "sac_sponsor": "John Smith",
            "abbreviation": "WTCCC",
            "accession_number": null,
            "description": "Some study on something",
            "state": "active",
            "contaminated_human_dna": "No",
            "contains_human_dna": "No",
            "remove_x_and_autosomes": false,
            "commercially_available": "No",
            "data_release_sort_of_study": "genomic sequencing",
            "data_release_strategy": "open",
            "data_release_timing": "standard",
            "study_visibility": "Hold",
            "array_express_accession_number": "AE111",
            "ega_policy_accession_number": "EGA222",
            "ega_dac_accession_number": "DAC333",
            "projects": "http://localhost:3000/0_5/studies/00000000-1111-2222-3333-444444444444/projects",
            "samples": "http://localhost:3000/0_5/studies/00000000-1111-2222-3333-444444444444/samples",

            "id": 1,
            "created_at": "2010-09-16T13:45:00+01:00"
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a study that does not exist
    When I GET the API path "/studies/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular study
    Given I have an active study called "Testing the JSON API"
    And the study "Testing the JSON API" has samples which need x and autosome data removed
    And the UUID for the study "Testing the JSON API" is "00000000-1111-2222-3333-444444444444"
    And the faculty sponsor for study "Testing the JSON API" is "John Smith"
    When I GET the API path "/studies/00000000-1111-2222-3333-444444444444"
    Then ignoring "updated_at|id" the JSON should be:
      """
      {
        "study": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Testing the JSON API",
          "ethically_approved": false,
          "reference_genome": "",
          "study_type":  "Not specified",
          "abstract": null,
          "sac_sponsor": "John Smith",
          "abbreviation": "WTCCC",
          "accession_number": null,
          "description": "Some study on something",
          "state": "active",
          "contaminated_human_dna": "No",
          "contains_human_dna": "No",
          "remove_x_and_autosomes": true,
          "commercially_available": "No",
          "study_visibility": "Hold",
          "data_release_sort_of_study": "genomic sequencing",
          "data_release_strategy": "open",
          "data_release_timing": "standard",
          "projects": "http://localhost:3000/0_5/studies/00000000-1111-2222-3333-444444444444/projects",
          "samples": "http://localhost:3000/0_5/studies/00000000-1111-2222-3333-444444444444/samples",

          "id": 1,
          "created_at": "2010-09-16T13:45:00+01:00"
        }
      }
      """
