# rake features FEATURE=features/plain/api/asset_links.feature
@api @json @asset_link @asset @allow-rescue
Feature: Interacting with asset_links through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API

  Scenario: Listing all of the asset_links that exist if there aren't any
    When I GET the API path "/asset_links"
    Then the JSON should be an empty array

  Scenario: Listing all of the asset_links that exist
    Given a plate with uuid "UUID-plate123" exists
    And a well with uuid "UUID-well456" exists
    Given a asset_link with uuid "00000000-1111-2222-3333-444444444444" exists and connects "UUID-plate123" and "UUID-well456"

    When I GET the API path "/asset_links"
    Then ignoring "internal_id|descendant_internal_id|ancestor_internal_id" the JSON should be:
      """
      [
        {
          "asset_link": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "ancestor_uuid":"UUID-plate123",
            "ancestor_type": "plates",
            "descendant_type": "wells",
            "descendant_uuid": "UUID-well456",

            "ancestor_internal_id": 20,
            "descendant_internal_id": 19,

            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00"
          }
        }
      ]
      """

  Scenario: Retrieving the JSON for a asset_link that does not exist
    When I GET the API path "/asset_links/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular asset_link
    Given a plate with uuid "UUID-plate123" exists
    And a well with uuid "UUID-well456" exists
    Given a asset_link with uuid "00000000-1111-2222-3333-444444444444" exists and connects "UUID-plate123" and "UUID-well456"

    When I GET the API path "/asset_links/00000000-1111-2222-3333-444444444444"
    Then ignoring "internal_id|descendant_internal_id|ancestor_internal_id" the JSON should be:
      """
        {
          "asset_link": {
            "uuid": "00000000-1111-2222-3333-444444444444",
            "ancestor_uuid":"UUID-plate123",
            "ancestor_type": "plates",
            "descendant_type": "wells",
            "descendant_uuid": "UUID-well456",

            "ancestor_internal_id": 20,
            "descendant_internal_id": 19,

            "created_at": "2010-09-16T13:45:00+01:00",
            "updated_at": "2010-09-16T13:45:00+01:00"
          }
        }
      """
