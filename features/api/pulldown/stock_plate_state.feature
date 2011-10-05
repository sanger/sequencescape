@api @json @plate @single-sign-on @new-api @barcode-service
Feature: Pulldown stock DNA plate state varies based on the presence of submissions
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given the plate barcode webservice returns "1000001"
      And a "WGS stock DNA" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"

  Scenario: When the stock plate has no submission its state is 'pending'
    When I GET the API path "/00000000-1111-2222-3333-000000000001"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "uuid": "00000000-1111-2222-3333-000000000001",
          "state": "pending"
        }
      }
      """

  Scenario: When the stock plate has submissions then its state is 'passed'
    Given the plate with UUID "00000000-1111-2222-3333-000000000001" has been submitted to "Pulldown WGS - HiSeq Paired end sequencing"

    When I GET the API path "/00000000-1111-2222-3333-000000000001"
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "uuid": "00000000-1111-2222-3333-000000000001",
          "state": "passed"
        }
      }
      """
