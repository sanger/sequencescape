@api @json @asset @search @single-sign-on @new-api @barcode_search @barcode-service
Feature: The search interface should return outstanding Pre-PCR plates
  Background:
    Given all of this is happening at exactly "12-Jun-2012 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given the UUID for the search "Find outstanding Illumina-B pre-PCR plates" is "00000000-1111-2222-3333-444444444444"

    Given the plate barcode webservice returns "1000001"
    And the plate barcode webservice returns "1000002"
    And the plate barcode webservice returns "1000003"
    And the plate barcode webservice returns "1000004"

    Given a "Stock Plate" plate called "stock plate" exists
    And a "ILB_STD_PREPCR" plate called "Pending PrePCR" exists
    And the UUID for the plate "Pending PrePCR" is "00000000-1111-2222-3333-000000000001"
    And a "ILB_STD_PREPCR" plate called "Started PrePCR" exists
    And the UUID for the plate "Started PrePCR" is "00000000-1111-2222-3333-000000000002"
    And a "ILB_STD_PREPCR" plate called "Passed PrePCR" exists
    And the UUID for the plate "Passed PrePCR" is "00000000-1111-2222-3333-000000000003"
    And pending transfer requests exist between 1 wells on "stock plate" and "Pending PrePCR"
    And started transfer requests exist between 1 wells on "stock plate" and "Started PrePCR"
    And passed transfer requests exist between 1 wells on "stock plate" and "Passed PrePCR"

  Scenario: I should be able to find Illumina-B Plates
    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
      """
      {
        "search": {
        }
      }
      """

    Then the HTTP response should be "300 Multiple Choices"
    And the JSON should match the following for the specified fields:
      """
      {
        "size":2,
        "searches":[{
          "name":"Pending PrePCR",
          "plate_purpose":{"name":"ILB_STD_PREPCR"},
          "uuid":"00000000-1111-2222-3333-000000000001",
          "state":"pending"
        }, {
          "name":"Started PrePCR",
          "plate_purpose":{"name":"ILB_STD_PREPCR"},
          "uuid":"00000000-1111-2222-3333-000000000002",
          "state":"started"
        }]
      }
      """
