@api @json @sample @single-sign-on @new-api
Feature: Access samples through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual samples through their UUID
  And I want to be able to perform other operations to individual samples
  And I want to be able to do all of this only knowing the UUID of a sample
  And I understand I will never be able to delete a sample through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @update @error
  Scenario Outline: Updating the sample associated with the UUID which gives an error
    Given a sample called "testing_the_api_exists" with ID 1
    And the UUID for the sample with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {
          <json>
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    And the JSON should be:
      """
      {
        "content": {
          "<field>": [<errors>]
        }
      }
      """

    Scenarios:
      | json                                                  | field                        | errors                        |
      | "sanger": { "name": "valid_but_not_permitted" }       | sanger.name                  | "is read-only"                |
      | "supplier": { "measurements": { "gender": "Weird" } } | supplier.measurements.gender | "is not included in the list" |
      | "data_release": { "visibility": "Please" }            | data_release.visibility      | "is read-only"                |
      | "source": { "dna_source": "Blood donation" }          | source.dna_source            | "is not included in the list" |

  @update
  Scenario: Updating the sample associated with the UUID
    Given a sample called "testing_the_api_exists" with ID 1
    And the UUID for the sample with ID 1 is "00000000-1111-2222-3333-444444444444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample": {

        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """

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
    Given a sample called "testing_the_api" with ID 1
      And the UUID for the sample with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the sample called "testing_the_api" is Male
      And the GC content of the sample called "testing_the_api" is Neutral
      And the DNA source of the sample called "testing_the_api" is Genomic
      And the SRA status of the sample called "testing_the_api" is Hold
      And the sample called "testing_the_api" is 10 minutes old
      And the dosage of the sample called "testing_the_api" is 10 something
      And the fields of the sample_metadata for the sample called "testing_the_api" are prepopulated

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "sample_tubes": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/sample_tubes"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "sanger": {
            "name": "testing_the_api",
            "sample_id": null,
            "resubmitted": null,
            "description": "sample_description"
          },
          "supplier": {
            "sample_name": "supplier_name",
            "storage_conditions": "sample_storage_conditions",

            "collection": {
              "date": "date_of_sample_collection"
            },
            "extraction": {
              "date": "date_of_sample_extraction",
              "method": "sample_extraction_method"
            },
            "purification": {
              "purified": "sample_purified",
              "method": "purification_method"
            },
            "measurements": {
              "volume": "volume",
              "concentration": "concentration",
              "gc_content": "Neutral",
              "gender": "Male",
              "concentration_determined_by": "concentration_determined_by"
            }
          },
          "source": {
            "dna_source": "Genomic",
            "cohort": "cohort",
            "country": "country_of_origin",
            "region": "geographical_region",
            "ethnicity": "ethnicity",
            "control": null
          },
          "family": {
            "mother": "mother",
            "father": "father",
            "replicate": "replicate",
            "sibling": "sibling"
          },
          "taxonomy": {
            "id": null,
            "strain": "sample_strain_att",
            "common_name": "sample_common_name",
            "organism": "organism"
          },
          "reference": {
            "genome": null
          },
          "data_release": {
            "visibility": "Hold",
            "public_name": "sample_public_name",
            "description": "sample_description",

            "metagenomics": {
              "genotype": "genotype",
              "phenotype": "phenotype",
              "age": "10 minutes",
              "developmental_stage": "developmental_stage",
              "cell_type": "cell_type",
              "disease_state": "disease_state",
              "compound": "compound",
              "dose": "10 something",
              "immunoprecipitate": "immunoprecipitate",
              "growth_condition": "growth_condition",
              "rnai": "rnai",
              "organism_part": "organism_part",
              "time_point": "time_point",
              "treatment": "treatment",
              "subject": "subject",
              "disease": "disease"
            },
            "managed": {
              "treatment": "treatment",
              "subject": "subject",
              "disease": "disease"
            }
          }
        },
        "uuids_to_ids": {
          "00000000-1111-2222-3333-444444444444": 1
        }
      }
      """
