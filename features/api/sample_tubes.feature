@api @json @sample_tube @single-sign-on @new-api
Feature: Access sample tubes through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual sample tubes through their UUID
  And I want to be able to perform other operations to individual sample tubes
  And I want to be able to do all of this only knowing the UUID of a sample tube
  And I understand I will never be able to delete a sample tube through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  @read
  Scenario: Reading the JSON for a UUID
    Given a sample tube called "Testing the API" with ID 1
    And the UUID for the sample tube "Testing the API" is "00000000-1111-2222-3333-444444444444"
    And the barcode for the sample tube "Testing the API" is "42"

    Given a sample called "sample_testing_the_api" exists
    And the UUID for the sample "sample_testing_the_api" is "00000000-1111-2222-3333-888888888888"
    And the sample "sample_testing_the_api" is in the sample tube "Testing the API"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "sample_tube": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",

          "name": "Testing the API",
          "qc_state": "",
          "closed": false,
          "concentration": null,
          "volume": null,
          "scanned_in_date": "",

          "barcode": {
            "prefix": "NT",
            "number": "42",
            "ean13": "3980000042705",
            "two_dimensional": null,
            "type": 2
          },

          "aliquots": [
            {
              "sample": {
              }
            }
          ],
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/requests"
            }
          },
          "library_tubes": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/library_tubes"
            }
          }
        }
      }
      """
