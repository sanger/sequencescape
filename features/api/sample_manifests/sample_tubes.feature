@api @json @sample_manifest @sample_tube @single-sign-on @new-api @barcode-service
Feature: Access sample manifests through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual sample manifests through their UUID
  And I want to be able to perform other operations to individual sample manifests
  And I want to be able to do all of this only knowing the UUID of a sample manifest
  And I understand I will never be able to delete a sample manifest through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given I have an "active" study called "Testing sample manifests"
    And the UUID for the study "Testing sample manifests" is "22222222-3333-4444-5555-000000000000"

    Given a supplier called "John's Genes" with ID 2
    And the UUID for the supplier "John's Genes" is "33333333-1111-2222-3333-444444444444"

  @read
  Scenario: Reading the JSON for a UUID
    Given the sample manifest exists with ID 1
    And the UUID for the sample manifest with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the sample manifest with ID 1 is owned by study "Testing sample manifests"
    And the sample manifest with ID 1 is supplied by "John's Genes"
    And the sample manifest with ID 1 is for 1 sample tube

    Given the "1D Tube" barcode printer "d999bc" exists
    Given the sample manifest with ID 1 has been processed
    And the barcode of the last sample tube is "9999"
    And the Sanger sample ID of the last sample is "WTCCC99"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample_manifest": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            }
          },
          "supplier": {
            "actions": {
              "read": "http://www.example.com/api/1/33333333-1111-2222-3333-444444444444"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "last_errors": null,

          "samples": [
            {
              "container": {
                "barcode": "NT9999J"
              },
              "sample": {
                "sanger": {
                  "sample_id": "WTCCC99"
                }
              }
            }
          ]
        }
      }
      """

  # NOTE: The 'container' element is not really empty here, I just can't guarantee the barcode inside it!
  @create
  Scenario: Creating a sample tube sample manifest through a study
    Given the UUID of the next sample manifest created will be "00000000-1111-2222-3333-444444444444"
    And the Sanger sample IDs will be sequentially generated

    When I POST the following JSON to the API path "/22222222-3333-4444-5555-000000000000/sample_manifests/create_for_tubes":
      """
      {
        "sample_manifest": {
          "supplier": "33333333-1111-2222-3333-444444444444",
          "count": 1
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample_manifest": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            }
          },
          "supplier": {
            "actions": {
              "read": "http://www.example.com/api/1/33333333-1111-2222-3333-444444444444"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "pending",
          "last_errors": null,

          "samples": [
            {
              "container": {

              },
              "sample": {
                "sanger": {
                  "sample_id": "WTCCC1"
                }
              }
            }
          ]
        }
      }
      """
