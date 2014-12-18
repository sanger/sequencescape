@api @json @asset_rack @single-sign-on @new-api
Feature: Access asset_racks through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual asset_racks through their UUID
  And I want to be able to perform other operations to individual asset_racks
  And I want to be able to do all of this only knowing the UUID of a asset_rack
  And I understand I will never be able to delete a asset_rack through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given the full asset rack exists with ID 1
      And the asset rack with ID 1 has a barcode of "1220000001831"
      And the UUID for the asset rack with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the UUID for the last asset rack purpose is "11111111-2222-3333-4444-555555555555"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "asset_rack": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "asset_rack_purpose": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
            }
          },
          "strip_tubes": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/strip_tubes"
            }
          },

          "barcode": {
            "prefix": "DN",
            "number": "1",
            "ean13": "1220000001831",
            "type": 1
          },

          "uuid": "00000000-1111-2222-3333-444444444444"
        }
      }
      """

    When I GET the API path "/00000000-1111-2222-3333-444444444444/strip_tubes"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "plates": [{

        }],
        "size":   1
      }
      """

