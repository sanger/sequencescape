@api @json @sample_manifest @plate @single-sign-on @new-api @barcode-service
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

    Given I have an "active" study called "Testing sample manifests"
    And the UUID for the study "Testing sample manifests" is "22222222-3333-4444-5555-000000000000"

    Given a supplier called "John's Genes" with ID 2
    And the UUID for the supplier "John's Genes" is "33333333-1111-2222-3333-444444444444"

    Given the "96 Well Plate" barcode printer "d999bc" exists
    And the plate barcode webservice returns "SQPD-1234567"

  @read
  Scenario: Reading the JSON for a UUID
    Given the sample manifest exists with ID 1
    And the UUID for the sample manifest with ID 1 is "00000000-1111-2222-3333-444444444444"
    And the sample manifest with ID 1 is owned by study "Testing sample manifests"
    And the sample manifest with ID 1 is supplied by "John's Genes"
    And the sample manifest with ID 1 is for 1 plate

    Given the sample manifest with ID 1 has been processed

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample_manifest": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
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

          "samples": []
        }
      }
      """

  @update
  Scenario: Updating a manifest
    Given the sample manifest exists with ID 1
      And the UUID for the sample manifest with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the sample manifest with ID 1 is owned by study "Testing sample manifests"
      And the sample manifest with ID 1 is supplied by "John's Genes"
      And the sample manifest with ID 1 is for 1 plate

    Given the sample manifest with ID 1 has been processed
      And all samples have a Sanger sample ID based on "WTCCC"
      And all samples have sequential UUIDs based on "11111111-2222-3333-4444"

    When I PUT the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "sample_manifest": {
          "samples": [
            {
              "uuid": "11111111-2222-3333-4444-000000000002",

              "supplier": {
                "sample_name": "flurby_wurby_sample",
                "measurements": {
                  "volume": "100",
                  "concentration": "10"
                }
              }
            }
          ]
        }
      }
      """
    Then the HTTP response should be "410 GONE"
    And the JSON should match the following for the specified fields:
      """
      { "general": ["requested action is no longer supported"] }
      """

  @create
  Scenario: Creating a plate sample manifest through a study
    Given the UUID of the next sample manifest created will be "00000000-1111-2222-3333-444444444444"
    And the Sanger sample IDs will be sequentially generated

    When I POST the following JSON to the API path "/22222222-3333-4444-5555-000000000000/sample_manifests/create_for_plates":
      """
      {
        "sample_manifest": {
          "supplier": "33333333-1111-2222-3333-444444444444",
          "count": 1
        }
      }
      """
   Then the HTTP response should be "410 GONE"
    And the JSON should match the following for the specified fields:
      """
      { "general": ["requested action is no longer supported"] }
      """
