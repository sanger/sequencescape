@api @json @sample @single-sign-on @new-api
Feature: Access samples through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to read individual samples through their UUID
  And I want to be able to perform other operations to individual samples
  And I want to be able to do all of this only knowing the UUID of a sample
  And I understand I will never be able to delete a sample through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given a sample called "testing_the_api" with UUID "00000000-1111-2222-3333-444444444444"
      And the sample called "testing_the_api" is Male
      And the GC content of the sample called "testing_the_api" is Neutral
      And the DNA source of the sample called "testing_the_api" is Genomic
      And the SRA status of the sample called "testing_the_api" is Hold
      And the sample called "testing_the_api" is 10 weeks old
      And the dosage of the sample called "testing_the_api" is 10 something
      And the fields of the sample_metadata for the sample called "testing_the_api" are prepopulated

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
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
              "age": "10 weeks",
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
        }
      }
      """

@read
  Scenario: JSON rendering bug
    Given a sample called "testing_the_api" with UUID "00000000-1111-2222-3333-444444444444"
      And the sample called "testing_the_api" is Male
      And the GC content of the sample called "testing_the_api" is Neutral
      And the DNA source of the sample called "testing_the_api" is Genomic
      And the SRA status of the sample called "testing_the_api" is Hold
      And the sample called "testing_the_api" is 10 weeks old
      And the dosage of the sample called "testing_the_api" is 10 something
      And the description of the sample called "testing_the_api" contains quotes
      And the fields of the sample_metadata for the sample called "testing_the_api" are prepopulated

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "sanger": {
            "name": "testing_the_api",
            "sample_id": null,
            "resubmitted": null,
            "description": "something \"with\" quotes"
          }
        }
      }
      """

