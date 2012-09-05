# rake features FEATURE=features/plain/api/samples.feature
@api @json @sample @allow-rescue @sample_api
Feature: Interacting with samples through the API
  # NOTE: 'id' is displayed in the JSON but the JSON comparison step removes this
  Background:
    Given all of this is happening at exactly "2010-Sep-08 09:00:00+01:00"

    Given I am using version "0_5" of a legacy API

    Given there are no samples

  Scenario: Attempting to create a sample without required fields
    When I POST the following JSON to the API path "/samples":
      """
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "name": [ "can't be blank", "Sample name can only contain letters, numbers, _ or -" ]
      }
      """

  Scenario: Creating a sample
    When I POST the following JSON to the API path "/samples":
      """
      {
        "sample": {
          "name": "testing_the_json_api"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And ignoring "updated_at|id|uuid|sample_tubes" the JSON should be:
      """
      {
        "sample": {
          "name": "testing_the_json_api",
          "new_name_format": true,

          "replicate": null,
          "reference_genome": "",
          "organism": null,
          "sample_strain_att": null,
          "ethnicity": null,
          "gc_content": null,
          "mother": null,
          "sample_public_name": null,
          "supplier_plate_id": null,
          "sample_ebi_accession_number": null,
          "sample_common_name": null,
          "dna_source": null,
          "sample_taxon_id": null,
          "country_of_origin": null,
          "gender": null,
          "volume": null,
          "sample_sra_hold": null,
          "geographical_region": null,
          "sample_description": null,
          "father": null,
          "cohort": null,
          "empty_supplier_sample_name": null,
          "supplier_name": null,
          "updated_by_manifest": null,

          "created_at": "2010-09-08T09:00:00+01:00",

          "id": "1",
          "uuid": "00000000-1111-2222-3333-444444444444",
          "sample_tubes": "http://localhost:3000/0_5/samples/00000000-1111-2222-3333-444444444445/sample_tubes"
        }
      }
      """

    # Check it actually created the record and the associated sample tube!
    Then the sample "testing_the_json_api" should exist
    And the sample "testing_the_json_api" should have an associated sample tube

  Scenario: Listing all of the samples that exist if there aren't any
    When I GET the API path "/samples"
    Then the JSON should be an empty array

  Scenario: Listing all of the samples that exist
    Given the sample named "sample_testing_the_json_api" exists
    And the UUID for the sample "sample_testing_the_json_api" is "00000000-1111-2222-3333-444444444444"
    And the sanger sample id for sample "00000000-1111-2222-3333-444444444444" is "1STDY123"

    When I GET the API path "/samples"
    Then the HTTP response should be "200 OK"
    And ignoring "updated_at|id" the JSON should be:
      """
      [
        {
          "sample": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "name": "sample_testing_the_json_api",
            "sample_tubes": "http://localhost:3000/0_5/samples/00000000-1111-2222-3333-444444444444/sample_tubes",

            "replicate": null,
            "reference_genome": "",
            "organism": null,
            "sample_strain_att": null,
            "ethnicity": null,
            "gc_content": null,
            "mother": null,
            "sample_public_name": null,
            "supplier_plate_id": null,
            "sample_ebi_accession_number": null,
            "sample_common_name": null,
            "dna_source": null,
            "sample_taxon_id": null,
            "country_of_origin": null,
            "gender": null,
            "volume": null,
            "sample_sra_hold": null,
            "geographical_region": null,
            "sample_description": null,
            "father": null,
            "cohort": null,
            "sanger_sample_id": "1STDY123",
            "control": null,
            "sample_manifest_id": null,
            "empty_supplier_sample_name": null,
            "supplier_name": null,
            "updated_by_manifest": null,

            "created_at": "2010-09-08T09:00:00+01:00",
            "new_name_format": true,

            "id": 1
          }
        }
      ]
      """

  Scenario: Listing all of the samples that are associated with a study
    Given I have an active study called "Study testing the JSON API"
    And the sample named "sample_testing_the_json_api" exists
    And the sample "sample_testing_the_json_api" belongs to the study "Study testing the JSON API"
    And the UUID for the sample "sample_testing_the_json_api" is "00000000-1111-2222-3333-444444444444"
    And the UUID for the study "Study testing the JSON API" is "00000000-1111-2222-3333-555555555555"

    When I GET the API path "/studies/00000000-1111-2222-3333-555555555555/samples"
    Then the HTTP response should be "200 OK"
    And ignoring "updated_at|id" the JSON should be:
      """
      [
        {
          "sample": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "name": "sample_testing_the_json_api",
            "sample_tubes": "http://localhost:3000/0_5/samples/00000000-1111-2222-3333-444444444444/sample_tubes",

            "replicate": null,
            "reference_genome": "",
            "organism": null,
            "sample_strain_att": null,
            "ethnicity": null,
            "gc_content": null,
            "mother": null,
            "sample_public_name": null,
            "supplier_plate_id": null,
            "sample_ebi_accession_number": null,
            "sample_common_name": null,
            "dna_source": null,
            "sample_taxon_id": null,
            "country_of_origin": null,
            "gender": null,
            "volume": null,
            "sample_sra_hold": null,
            "geographical_region": null,
            "sample_description": null,
            "father": null,
            "cohort": null,
            "empty_supplier_sample_name": null,
            "supplier_name": null,
            "updated_by_manifest": null,

            "created_at": "2010-09-08T09:00:00+01:00",
            "new_name_format": true,

            "id": 1
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a particular sample when not attached to a study
    Given the sample named "sample_testing_the_json_api" exists
    And the UUID for the sample "sample_testing_the_json_api" is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/samples/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And ignoring "updated_at|id" the JSON should be:
      """
      {
        "sample": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "sample_testing_the_json_api",
          "sample_tubes": "http://localhost:3000/0_5/samples/00000000-1111-2222-3333-444444444444/sample_tubes",

          "replicate": null,
          "reference_genome": "",
          "organism": null,
          "sample_strain_att": null,
          "ethnicity": null,
          "gc_content": null,
          "mother": null,
          "sample_public_name": null,
          "supplier_plate_id": null,
          "sample_ebi_accession_number": null,
          "sample_common_name": null,
          "dna_source": null,
          "sample_taxon_id": null,
          "country_of_origin": null,
          "gender": null,
          "volume": null,
          "sample_sra_hold": null,
          "geographical_region": null,
          "sample_description": null,
          "father": null,
          "cohort": null,
          "empty_supplier_sample_name": null,
          "supplier_name": null,
          "updated_by_manifest": null,

          "created_at": "2010-09-08T09:00:00+01:00",
          "new_name_format": true,

          "id": 1
        }
      }
      """

  Scenario: Retrieving the JSON for a particular sample
    Given I have an active study called "Study for testing the JSON API"
    Given a reference genome table
    And the reference genome for study "Study for testing the JSON API" is "Homo_sapiens (GRCh37_53)"
    And the sample named "sample_testing_the_json_api" exists
    And the UUID for the sample "sample_testing_the_json_api" is "00000000-1111-2222-3333-444444444444"
    And the sample "sample_testing_the_json_api" belongs to the study "Study for testing the JSON API"
    And the sanger sample id for sample "00000000-1111-2222-3333-444444444444" is "1STDY123"

    When I GET the API path "/samples/00000000-1111-2222-3333-444444444444"
    Then ignoring "updated_at|id" the JSON should be:
      """
      {
        "sample": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "sample_testing_the_json_api",
          "reference_genome": "Homo_sapiens (GRCh37_53)",
          "sample_tubes": "http://localhost:3000/0_5/samples/00000000-1111-2222-3333-444444444444/sample_tubes",

          "replicate": null,
          "organism": null,
          "sample_strain_att": null,
          "ethnicity": null,
          "gc_content": null,
          "mother": null,
          "sample_public_name": null,
          "supplier_plate_id": null,
          "sample_ebi_accession_number": null,
          "sample_common_name": null,
          "dna_source": null,
          "sample_taxon_id": null,
          "country_of_origin": null,
          "gender": null,
          "volume": null,
          "sample_sra_hold": null,
          "geographical_region": null,
          "sample_description": null,
          "father": null,
          "cohort": null,
          "sanger_sample_id": "1STDY123",
          "control": null,
          "sample_manifest_id": null,
          "empty_supplier_sample_name": null,
          "supplier_name": null,
          "updated_by_manifest": null,

          "created_at": "2010-09-08T09:00:00+01:00",
          "new_name_format": true,

          "id": 1
        }
      }
      """


  Scenario: Given a sample has a supplier name set
    Given I have an active study called "Study for testing the JSON API"
    Given a reference genome table
    And the reference genome for study "Study for testing the JSON API" is "Homo_sapiens (GRCh37_53)"
    And the sample named "sample_testing_the_json_api" exists
    And the UUID for the sample "sample_testing_the_json_api" is "UUID-1234567890"
    And the sample "sample_testing_the_json_api" belongs to the study "Study for testing the JSON API"
    And the sanger sample id for sample "UUID-1234567890" is "1STDY123"
    And the sample "sample_testing_the_json_api" has a supplier name of "My sample"

    When I retrieve the JSON for the sample "sample_testing_the_json_api"
    Then ignoring "updated_at|id" the JSON should be:
      """
      {
        "sample": {
          "uuid": "UUID-1234567890",
          "name": "sample_testing_the_json_api",
          "reference_genome": "Homo_sapiens (GRCh37_53)",
          "sample_tubes": "http://localhost:3000/0_5/samples/UUID-1234567890/sample_tubes",

          "replicate": null,
          "organism": null,
          "sample_strain_att": null,
          "ethnicity": null,
          "gc_content": null,
          "mother": null,
          "sample_public_name": null,
          "supplier_plate_id": null,
          "sample_ebi_accession_number": null,
          "sample_common_name": null,
          "dna_source": null,
          "sample_taxon_id": null,
          "country_of_origin": null,
          "gender": null,
          "volume": null,
          "sample_sra_hold": null,
          "geographical_region": null,
          "sample_description": null,
          "father": null,
          "cohort": null,
          "sanger_sample_id": "1STDY123",
          "control": null,
          "sample_manifest_id": null,
          "empty_supplier_sample_name": null,
          "supplier_name": "My sample",
          "updated_by_manifest": null,

          "created_at": "2010-09-08T09:00:00+01:00",
          "new_name_format": true,

          "id": 1
        }
      }
      """


  Scenario: Updating an existing sample without required fields
    Given the sample named "sample_testing_the_json_api" exists
    And the UUID for the sample "sample_testing_the_json_api" is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/samples/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {
          "name": ""
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "name": ["can't be blank", "cannot be changed", "Sample name can only contain letters, numbers, _ or -"]
      }
      """

  Scenario: Updating an existing sample
    Given a reference genome table
    Given the sample named "sample_testing_the_json_api" exists
    And the UUID for the sample "sample_testing_the_json_api" is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/samples/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {
          "reference_genome": "Staphylococcus_aureus (NCTC_8325)"
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the HTTP response body should be empty
    And the reference genome for the sample "sample_testing_the_json_api" should be "Staphylococcus_aureus (NCTC_8325)"
