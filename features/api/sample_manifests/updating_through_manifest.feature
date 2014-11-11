@api @json @sample_manifest @sample_tube @single-sign-on @new-api @barcode-service @update
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

    Given the sample manifest exists with ID 1
      And the UUID for the sample manifest with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the sample manifest with ID 1 is owned by study "Testing sample manifests"
      And the sample manifest with ID 1 is supplied by "John's Genes"
      And the sample manifest with ID 1 is for 1 sample tube

    Given the "1D Tube" barcode printer "d999bc" exists
    Given the sample manifest with ID 1 has been processed
      And the barcode of the last sample tube is "9999"

    Given the Sanger sample ID of the last sample is "WTCCC99"
      And the UUID for the last sample is "11111111-2222-3333-4444-000000000001"
      And the supplier sample name of the last sample is "Original Name"

  Scenario: Updating a manifest after the samples have been updated by another manifest does not change the information
    Given the last sample has been updated by a manifest

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample_manifest": {
          "samples": [
            {
              "uuid": "11111111-2222-3333-4444-000000000001",

              "supplier": {
                "sample_name": "flurby_wurby_sample",
                "measurements": {
                  "concentration": 10,
                  "volume": 100
                }
              }
            }
          ]
        }
      }
      """
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
                },
                "supplier": {
                  "sample_name": "Original Name"
                }
              }
            }
          ]
        }
      }
      """

  @override
  Scenario: Updating a manifest after the samples have been updated by another manifest changes information when forced
    Given the last sample has been updated by a manifest

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample_manifest": {
          "override_previous_manifest": true,
          "samples": [
            {
              "uuid": "11111111-2222-3333-4444-000000000001",

              "supplier": {
                "sample_name": "flurby_wurby_sample",
                "measurements": {
                  "concentration": 10,
                  "volume": 100
                }
              }
            }
          ]
        }
      }
      """
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
                "supplier": {
                  "sample_name": "flurby_wurby_sample"
                },
                "sanger": {
                  "sample_id": "WTCCC99"
                }
              }
            }
          ]
        }
      }
      """

  @error
  Scenario Outline: Updating a manifest where required fields are missing
    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample_manifest": {
          "samples": [
            {
              "uuid": "11111111-2222-3333-4444-000000000001",

              "supplier": {
                "sample_name": "flurby_wurby_sample",
                "measurements": {
                  <field set>
                }
              }
            }
          ]
        }
      }
      """
    Then the HTTP response should be "422 Unprocessable Entity"
    Then the JSON should be:
      """
      {
        "content": { <error> }
      }
      """

    Examples:
      | field set          | error                                                                        |
      | "volume":100       | "samples.supplier.measurements.concentration":["can't be blank for WTCCC99"] |
      | "concentration":10 | "samples.supplier.measurements.volume":["can't be blank for WTCCC99"]        |
