@api @json @plate @single-sign-on @new-api
Feature: Access plates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to see and update asset metadata

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

  @read
  Scenario: Reading the JSON for a UUID
    Given a custom metadatum collection exists with ID 7
    And the UUID for the custom metadatum collection with ID 7 is "00000000-1111-2222-3333-444444444444"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:

  """
      {
        "custom_metadatum_collection": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "asset": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444445"
            }
          },

          "user": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444446"
            }
          },

          "metadata": { "Key1": "Value1", "Key2": "Value2"},

          "uuid": "00000000-1111-2222-3333-444444444444"
        }

      }

  """

  Scenario: Creating a custom_metadatum_collection

    Given the labware and the user exist and have UUID
    When I make an authorised POST with the following JSON to the API path "/custom_metadatum_collections":
      """
      {
        "custom_metadatum_collection": {
          "user": "00000000-1111-2222-3333-444444444446",
          "asset": "00000000-1111-2222-3333-444444444445",
          "metadata": {"Key1": "Value1", "Key2": "Value2"}
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "custom_metadatum_collection": {
          "user": {
            "uuid":"00000000-1111-2222-3333-444444444446"
          },
          "asset": {
            "uuid":"00000000-1111-2222-3333-444444444445"
          },
          "metadata": {"Key1": "Value1", "Key2": "Value2"}
        }
      }
      """

  Scenario: Updating metadata

    Given a custom metadatum collection exists with ID 1
    And the UUID for the custom metadatum collection with ID 1 is "00000000-1111-2222-3333-444444444444"
    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "custom_metadatum_collection": {
          "metadata": {"Key1": "Value1", "Key3": "Value3", "Key4": "Value4"}
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "custom_metadatum_collection": {
          "metadata": {"Key1": "Value1", "Key3": "Value3", "Key4": "Value4"}
        }
      }
      """
