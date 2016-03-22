@api @json @asset @search @single-sign-on @new-api @barcode_search
Feature: Searching for assets by barcode
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @search_assets @single
  Scenario Outline: Looking up a single asset by barcode
    Given the UUID for the search "Find assets by barcode" is "00000000-1111-2222-3333-444444444444"

    Given a <asset_type> called "Testing the API 1" with ID 1
      And the <asset_type> "Testing the API 1" has a barcode of "<barcode>"
      And the UUID for the <asset_type> "Testing the API 1" is "11111111-2222-3333-4444-000000000001"

    Given a <asset_type> called "Testing the API 2" with ID 2
      And the <asset_type> "Testing the API 2" has a barcode of "<barcode_2>"
      And the UUID for the <asset_type> "Testing the API 2" is "11111111-2222-3333-4444-000000000002"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "barcode": <barcode_2>
        }
      }
      """
    Then the HTTP response should be "301 Moved Permanently"
     And the JSON should match the following for the specified fields:
      """
      {
        "<model_name>": {
          "name": "Testing the API 2",
          "uuid": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Examples:
      | asset_type             | model_name  | barcode       | barcode_2     |
      # | control plate          | plate       | 1220000123724 | 1220000999701 |
      # | dilution plate         | plate       | 1220000123724 | 1220000999701 |
      # | gel dilution plate     | plate       | 1930000123708 | 1930000999686 |
      # | pico assay a plate     | plate       | 4330000123802 | 4330000999780 |
      # | pico assay b plate     | plate       | 4340000123849 | 4340000999826 |
      # | pico assay plate       | plate       | 4330000123802 | 4330000999780 |
      # | pico dilution plate    | plate       | 4360000123694 | 4360000999671 |
      # | plate                  | plate       | 1220000123724 | 1220000999701 |
      # | working dilution plate | plate       | 6250000123818 | 6250000999796 |
      | sample tube            | sample_tube | 3980012344750 | 3980012345764 |



  @single @sample_tube @error
  Scenario: Looking up a non-existant barcode
    Given the UUID for the search "Find assets by barcode" is "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/first":
      """
      {
        "search": {
          "barcode": 3980012345764
        }
      }
      """
    Then the HTTP response should be "404 Not Found"
     And the JSON should be:
      """
      { "general": [ "no resources found with that search criteria" ] }
      """

  @multiple @sample_tube
  Scenario: Looking up multiple assets by barcode
    Given the UUID for the search "Find assets by barcode" is "00000000-1111-2222-3333-444444444444"

    Given a sample tube called "Testing the API 1" with ID 1
      And the sample tube "Testing the API 1" has a barcode of "3980012344750"
      And the UUID for the sample tube "Testing the API 1" is "11111111-2222-3333-4444-000000000001"

    Given a sample tube called "Testing the API 2" with ID 2
      And the sample tube "Testing the API 2" has a barcode of "3980012345764"
      And the UUID for the sample tube "Testing the API 2" is "11111111-2222-3333-4444-000000000002"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
      """
      {
        "search": {
          "barcode": 3980012345764
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
            "uuid": "11111111-2222-3333-4444-000000000002"
          }
        ]
      }
      """

  @multiple @sample_tube @error
  Scenario: Looking up a non-existant barcode with all
    Given the UUID for the search "Find assets by barcode" is "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
      """
      {
        "search": {
          "barcode": 3980012345764
        }
      }
      """
    Then the HTTP response should be "300 Multiple Choices"
     And the JSON should be:
      """
      {
        "searches": [],
        "size": 0
      }
      """
