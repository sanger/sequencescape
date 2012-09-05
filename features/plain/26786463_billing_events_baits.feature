@api @json @billing_event @allow-rescue
Feature: Interacting with billing_events that include bait_libraries through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"
    Given I have a billing event with UUID "00000000-1111-2222-3333-444444444444" and a bait library
    Given I am using version "0_5" of a legacy API

  Scenario: Retrieving the JSON for a particular billing_event

    When I GET the API path "/billing_events/00000000-1111-2222-3333-444444444444"
    Then ignoring "internal_id|project_internal_id|project_uuid|request_uuid|request_internal_id|reference|updated_at" the JSON should be:
      """
      {
        "billing_event": {
          "uuid": "00000000-1111-2222-3333-444444444444",
          "quantity": 1,
          "kind": "charge",
          "description": "Unspecified",
          "project_name": "Test Project",
          "created_by": "abc123@example.com",
          "project_division": "Human variation",
          "project_cost_code": "Some Cost Code",
          "entry_date": "2010-09-16T13:45:00+01:00",
          "created_at": "2010-09-16T13:45:00+01:00",
          "updated_at": "2010-09-16T13:45:00+01:00",
          "price": 100,
          "request_type": "Paired end sequencing",
          "library_type": "Standard",
          "bait_library_type": "Standard",

          "internal_id": 1,
          "project_internal_id": 2,
          "project_uuid": "UUID-11111",
          "request_uuid": "UUID-22222",
          "request_internal_id": 3,
          "reference": "R123A456"
        }
      }
      """

  Scenario: Request types don't include bait_library_types
    Given I have a project called "Project testing the JSON API"
    And the UUID for the project "Project testing the JSON API" is "11111111-2222-3333-4444-ffffffffffff"

    Given I have an active study called "Study testing the JSON API"
    And the UUID for the study "Study testing the JSON API" is "22222222-2222-3333-4444-ffffffffffff"

    And the UUID of the next submission created will be "11111111-2222-3333-4444-111111111111"
    Given the project "Project testing the JSON API" has a "Pulldown library creation" quota of 10
    And I have a sample tube called "Tube"
    And the sample tube "Tube" has been involved in a "Pulldown library creation" request with the bait library "Mouse all exon" within the study "Study testing the JSON API" for the project "Project testing the JSON API"
    And all assets have sequential UUIDs based on "aaaaaaaa-1111-2222-3333"
    And all samples have sequential UUIDs based on "bbbbbbbb-1111-2222-3333"

    When I retrieve the JSON for all requests related to the sample tube "Tube"
    Then ignoring "((source_asset|source_asset_sample|target_asset|project|study|submission)_(internal_id|barcode)|id)|updated_at" the JSON should be:
      """
      [
        {
          "request":  {
            "uuid": "22222222-2222-3333-4444-100000000000",
            "source_asset_type": "sample_tubes",
            "request_type": "Pulldown library creation",
            "state": "pending",

            "target_asset_closed": false,
            "target_asset_state": "",
            "created_at": "2010-09-16T13:45:00+01:00",
            "source_asset_two_dimensional_barcode": null,
            "updated_at": "2010-09-16T13:45:00+01:00",
            "target_asset_type": "sample_tubes",
            "project_uuid": "11111111-2222-3333-4444-ffffffffffff",
            "project_url": "http://localhost:3000/0_5/projects/11111111-2222-3333-4444-ffffffffffff",
            "study_name": "Study testing the JSON API",
            "target_asset_two_dimensional_barcode": null,
            "source_asset_closed": false,
            "target_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000002",
            "source_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000001",
            "study_url": "http://localhost:3000/0_5/studies/22222222-2222-3333-4444-ffffffffffff",
            "project_name": "Project testing the JSON API",
            "study_uuid": "22222222-2222-3333-4444-ffffffffffff",

            "submission_uuid": "11111111-2222-3333-4444-111111111111",
            "submission_url": "http://localhost:3000/0_5/submissions/11111111-2222-3333-4444-111111111111",
            "user": "abc123",

            "source_asset_sample_uuid": "bbbbbbbb-1111-2222-3333-000000000001",
            "target_asset_name": "Study testing the JSON API - Target asset",
            "source_asset_state": "",
            "source_asset_name": "Tube",
            "source_asset_barcode_prefix": "NT",
            "target_asset_barcode_prefix": "DN",
            "fragment_size_required_to": "20",
            "fragment_size_required_from": "1",
            "library_type": "Standard",

            "priority": 0,

            "source_asset_barcode": "ignored in test because it varies uncontrollably",
            "target_asset_barcode": "ignored in test because it varies uncontrollably",

            "id": "ignored in test because it varies uncontrollably & you should use uuid instead",
            "target_asset_internal_id": "ignored in test because it varies uncontrollably & you should use target_asset_uuid instead",
            "project_internal_id": "ignored in test because it varies uncontrollably & you should use project_uuid instead",
            "source_asset_internal_id": "ignored in test because it varies uncontrollably & you should use source_asset_uuid instead",
            "source_asset_sample_internal_id": "ignored in test because it varies uncontrollably & you should use source_asset_sample_uuid instead",
            "study_internal_id": "ignored in test because it varies uncontrollably & you should use study_uuid instead"
          }
        }
      ]
      """
