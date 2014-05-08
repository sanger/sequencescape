@api @json @asset @search @single-sign-on @new-api @barcode_search @destination_barcode_search
Feature: Searching for assets by barcode
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API
    Given the UUID for the search "Find source assets by destination asset barcode" is "00000000-1111-2222-3333-444444444444"

  @multiple @plate
  Scenario: Looking up multiple source assets by destination asset barcode
    Given a plate called "Testing the API 1" with ID 1
      And the plate "Testing the API 1" has a barcode of "1220099999705"
      And the UUID for the plate "Testing the API 1" is "11111111-2222-3333-4444-000000000001"

    Given a plate called "Testing the API 2" with ID 2
      And the plate "Testing the API 2" has a barcode of "1220000222748"
      And the UUID for the plate "Testing the API 2" is "11111111-2222-3333-4444-000000000002"

    Given a plate called "Testing the API 3" with ID 3
      And the plate "Testing the API 3" has a barcode of "1220000333802"
      And the UUID for the plate "Testing the API 3" is "11111111-2222-3333-4444-000000000003"

    Given plate "11111111-2222-3333-4444-000000000002" is a source plate of "11111111-2222-3333-4444-000000000001"
      And plate "11111111-2222-3333-4444-000000000003" is a source plate of "11111111-2222-3333-4444-000000000001"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
      """
      {
        "search": {
          "barcode": 1220099999705
        }
      }
      """
    Then the HTTP response should be "300 Multiple Choices"
     And the JSON should match the following for the specified fields:
      """
      {
        "searches": [
          {
            "name": "Testing the API 2",
            "uuid": "11111111-2222-3333-4444-000000000002",
            "barcode": {
              "ean13": "1220000222748"
            }
          },
          {
            "name": "Testing the API 3",
            "uuid": "11111111-2222-3333-4444-000000000003",
            "barcode": {
              "ean13": "1220000333802"
            }
          }
        ]
      }
      """

  @multiple @plate @error
  Scenario: Looking up multiple source assets by non-existant destination asset barcode
    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
      """
      {
        "search": {
          "barcode": 1220099999705
        }
      }
      """
    Then the HTTP response should be "300 Multiple Choices"
     And the JSON should be:
      """
      {
        "size": 0,
        "searches": []
      }
      """
