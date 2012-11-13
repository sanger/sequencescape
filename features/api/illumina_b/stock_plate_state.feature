@api @json @plate @single-sign-on @new-api @barcode-service
Feature: Illumina-b stock DNA plate state varies based on the presence of submissions
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given the plate barcode webservice returns "1000001"
      And a "ILB_STD_INPUT" plate called "Testing the API" exists
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"

  Scenario: A full stock plate with no submissions is in the pending state
    Given all wells on the plate "Testing the API" have unique samples

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

  Scenario: An empty stock plate with no submissions is in the pending state
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

  Scenario: An empty stock plate with submissions is in the pending state
    Given the plate with UUID "00000000-1111-2222-3333-000000000001" has been submitted to "Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing"

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

  Scenario: When the stock plate has full wells that do not have submissions it should be pending
    Given all wells on the plate "Testing the API" have unique samples
      And "A1-H6" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing"

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

  Scenario: When the stock plate has submissions on all of its full wells then its state is 'passed'
    Given all wells on the plate "Testing the API" have unique samples
      And the plate with UUID "00000000-1111-2222-3333-000000000001" has been submitted to "Illumina-B - Multiplexed WGS - HiSeq Paired end sequencing"

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
