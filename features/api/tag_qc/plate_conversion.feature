@api @json @plate_creation @single-sign-on @new-api @barcode-service
Feature: Access plate conversions through the API

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given a plate purpose called "Parent plate purpose" with UUID "11111111-2222-3333-4444-000000000001"
      And a plate purpose called "Child plate purpose" with UUID "11111111-2222-3333-4444-000000000002"
      And a plate purpose called "Original plate purpose" with UUID "11111111-2222-3333-4444-000000000003"
    Given a "Parent plate purpose" plate called "Testing the API" exists with barcode "SQPD-1000001"
      And the UUID for the plate "Testing the API" is "00000000-1111-2222-3333-000000000001"
    Given a "Original plate purpose" plate called "Converted Plate" exists with barcode "SQPD-1000002"
      And the UUID for the plate "Converted Plate" is "00000000-1111-2222-3333-000000000002"

  @create
  Scenario: Creating a plate conversion
    Given the UUID of the next plate conversion created will be "55555555-6666-7777-8888-000000000001"

    When I make an authorised POST with the following JSON to the API path "/plate_conversions":
      """
      {
        "plate_conversion": {
          "user": "99999999-8888-7777-6666-555555555555",
          "target": "00000000-1111-2222-3333-000000000002",
          "parent": "00000000-1111-2222-3333-000000000001",
          "purpose": "11111111-2222-3333-4444-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "plate_conversion": {
          "actions": {
            "read": "http://www.example.com/api/1/55555555-6666-7777-8888-000000000001"
          },
          "target": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-000000000002"
            }
          },

          "uuid": "55555555-6666-7777-8888-000000000001"
        }
      }
      """

    Then the plate "Converted Plate" has the parent "Testing the API"

