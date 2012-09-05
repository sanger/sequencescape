@api @json @request
Feature: Interacting with requests through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 16:15:00+01:00"

    Given I am using version "0_5" of a legacy API

    Given I have a project called "Project testing the JSON API"
    And the UUID for the project "Project testing the JSON API" is "11111111-2222-3333-4444-ffffffffffff"

    Given I have an active study called "Study testing the JSON API"
    And the UUID for the study "Study testing the JSON API" is "22222222-2222-3333-4444-ffffffffffff"

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-111111111111"

  Scenario: The list of requests is always empty if no type of tube is requested
    When I retrieve the JSON for all requests
    Then the JSON should be an empty array

  Scenario: Listing all of the requests related to sample tubes
    Given the project "Project testing the JSON API" has a "Pulldown library creation" quota of 10
    And I have a sample tube called "Tube"
    And the sample tube "Tube" has been involved in a "Pulldown library creation" request within the study "Study testing the JSON API" for the project "Project testing the JSON API"
    And all assets have sequential UUIDs based on "aaaaaaaa-1111-2222-3333"
    And all samples have sequential UUIDs based on "bbbbbbbb-1111-2222-3333"

    When I retrieve the JSON for all requests related to the sample tube "Tube"
    Then ignoring "((source_asset|source_asset_sample|target_asset|project|study|submission)_(internal_id|barcode)|id|updated_at)" the JSON should be:
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
            "created_at": "2010-09-16T16:15:00+01:00",
            "source_asset_two_dimensional_barcode": null,
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

  Scenario: Listing all of the requests related to library tubes
    Given the project "Project testing the JSON API" has a "Paired end sequencing" quota of 10
    And I have a library tube called "Tube"
    And the library tube "Tube" has been involved in a "Paired end sequencing" request within the study "Study testing the JSON API" for the project "Project testing the JSON API"
    And all assets have sequential UUIDs based on "aaaaaaaa-1111-2222-3333"
    And all samples have sequential UUIDs based on "bbbbbbbb-1111-2222-3333"

    When I retrieve the JSON for all requests related to the library tube "Tube"
    Then ignoring "((source_asset|target_asset|project|study|submission)_(internal_id|barcode)|id|updated_at)" the JSON should be:
      """
      [
        {
          "request":  {
            "uuid": "22222222-2222-3333-4444-100000000000",
            "source_asset_type": "library_tubes",
            "request_type": "Paired end sequencing",
            "state": "pending",

            "target_asset_closed": false,
            "target_asset_state": "",
            "created_at": "2010-09-16T16:15:00+01:00",
            "source_asset_two_dimensional_barcode": null,
            "target_asset_type": "library_tubes",
            "project_uuid": "11111111-2222-3333-4444-ffffffffffff",
            "project_url": "http://localhost:3000/0_5/projects/11111111-2222-3333-4444-ffffffffffff",
            "study_name": "Study testing the JSON API",

            "user": "abc123",

            "target_asset_two_dimensional_barcode": null,
            "source_asset_closed": false,
            "target_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000002",
            "source_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000001",
            "study_url": "http://localhost:3000/0_5/studies/22222222-2222-3333-4444-ffffffffffff",
            "project_name": "Project testing the JSON API",
            "study_uuid": "22222222-2222-3333-4444-ffffffffffff",
            "submission_uuid": "11111111-2222-3333-4444-111111111111",
            "submission_url": "http://localhost:3000/0_5/submissions/11111111-2222-3333-4444-111111111111",
            "target_asset_name": "Study testing the JSON API - Target asset",
            "source_asset_state": "",
            "source_asset_name": "Tube",
            "source_asset_barcode_prefix": "NT",
            "target_asset_barcode_prefix": "DN",
            "fragment_size_required_to": "21",
            "fragment_size_required_from": "1",

            "read_length": 76,

            "priority": 0,

            "source_asset_barcode": "ignored in test because it varies uncontrollably",
            "target_asset_barcode": "ignored in test because it varies uncontrollably",

            "id": "ignored in test because it varies uncontrollably & you should use uuid instead",
            "target_asset_internal_id": "ignored in test because it varies uncontrollably & you should use target_asset_uuid instead",
            "project_internal_id": "ignored in test because it varies uncontrollably & you should use project_uuid instead",
            "source_asset_internal_id": "ignored in test because it varies uncontrollably & you should use source_asset_uuid instead",
            "study_internal_id": "ignored in test because it varies uncontrollably & you should use study_uuid instead"
          }
        }
      ]
      """

  Scenario Outline: Retrieving the JSON for a request that is for library preparation
    Given the project "Project testing the JSON API" has a "<request type>" quota of 10
    And I have already made a "<request type>" request within the study "Study testing the JSON API" for the project "Project testing the JSON API"
    And all assets have sequential UUIDs based on "aaaaaaaa-1111-2222-3333"

    When I retrieve the JSON for the last request in the study "Study testing the JSON API"
    Then ignoring "((source_asset|target_asset|project|study|submission)_(internal_id|barcode)|id|updated_at)" the JSON should be:
      """
      {
        "request": {
          "uuid": "22222222-2222-3333-4444-100000000000",
          "state": "pending",

          "request_type": "<request type>",
          "created_at": "2010-09-16T16:15:00+01:00",

          "project_uuid": "11111111-2222-3333-4444-ffffffffffff",
          "project_url": "http://localhost:3000/0_5/projects/11111111-2222-3333-4444-ffffffffffff",
          "project_name": "Project testing the JSON API",

          "study_uuid": "22222222-2222-3333-4444-ffffffffffff",
          "study_url": "http://localhost:3000/0_5/studies/22222222-2222-3333-4444-ffffffffffff",
          "study_name": "Study testing the JSON API",

            "submission_uuid": "11111111-2222-3333-4444-111111111111",
            "submission_url": "http://localhost:3000/0_5/submissions/11111111-2222-3333-4444-111111111111",

          "user": "abc123",

          "source_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000001",
          "source_asset_name": "Study testing the JSON API - Source asset",
          "source_asset_state": "",
          "source_asset_type": "sample_tubes",
          "source_asset_closed": false,
          "source_asset_two_dimensional_barcode": null,

          "target_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000002",
          "target_asset_two_dimensional_barcode": null,
          "target_asset_name": "Study testing the JSON API - Target asset",
          "target_asset_type": "sample_tubes",
          "target_asset_state": "",
          "target_asset_closed": false,
          "source_asset_barcode_prefix": "DN",
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
          "study_internal_id": "ignored in test because it varies uncontrollably & you should use study_uuid instead"
        }
      }
      """

    Examples:
      |request type|
      |Library creation|
      |Multiplexed library creation|

  Scenario Outline: Retrieving the JSON for a request that is for sequencing
    Given the project "Project testing the JSON API" has a "<request type>" quota of 10
    And I have already made a "<request type>" request within the study "Study testing the JSON API" for the project "Project testing the JSON API"
    And all assets have sequential UUIDs based on "aaaaaaaa-1111-2222-3333"

    When I retrieve the JSON for the last request in the study "Study testing the JSON API"
    Then ignoring "((source_asset|target_asset|project|study|submission)_(internal_id|barcode)|id|updated_at)" the JSON should be:
      """
      {
        "request": {
          "uuid": "22222222-2222-3333-4444-100000000000",
          "state": "pending",

          "request_type": "<request type>",
          "created_at": "2010-09-16T16:15:00+01:00",

          "project_uuid": "11111111-2222-3333-4444-ffffffffffff",
          "project_url": "http://localhost:3000/0_5/projects/11111111-2222-3333-4444-ffffffffffff",
          "project_name": "Project testing the JSON API",

          "study_uuid": "22222222-2222-3333-4444-ffffffffffff",
          "study_url": "http://localhost:3000/0_5/studies/22222222-2222-3333-4444-ffffffffffff",
          "study_name": "Study testing the JSON API",
          "user": "abc123",
            "submission_uuid": "11111111-2222-3333-4444-111111111111",
            "submission_url": "http://localhost:3000/0_5/submissions/11111111-2222-3333-4444-111111111111",

          "source_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000001",
          "source_asset_name": "Study testing the JSON API - Source asset",
          "source_asset_state": "",
          "source_asset_type": "library_tubes",
          "source_asset_closed": false,
          "source_asset_two_dimensional_barcode": null,

          "target_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000002",
          "target_asset_two_dimensional_barcode": null,
          "target_asset_name": "Study testing the JSON API - Target asset",
          "target_asset_type": "library_tubes",
          "target_asset_state": "",
          "target_asset_closed": false,

          "source_asset_barcode_prefix": "DN",
          "target_asset_barcode_prefix": "DN",
          "fragment_size_required_to": "21",
          "fragment_size_required_from": "1",

          "read_length": 76,

          "priority": 0,

          "source_asset_barcode": "ignored in test because it varies uncontrollably",
          "target_asset_barcode": "ignored in test because it varies uncontrollably",

          "id": "ignored in test because it varies uncontrollably & you should use uuid instead",
          "target_asset_internal_id": "ignored in test because it varies uncontrollably & you should use target_asset_uuid instead",
          "project_internal_id": "ignored in test because it varies uncontrollably & you should use project_uuid instead",
          "source_asset_internal_id": "ignored in test because it varies uncontrollably & you should use source_asset_uuid instead",
          "study_internal_id": "ignored in test because it varies uncontrollably & you should use study_uuid instead"
        }
      }
      """

    Examples:
      |request type|
      |Single ended sequencing|
      |Paired end sequencing|

  @priority
  Scenario: Retrieving the JSON for a request which is owned by a user and has the priority flag set
    Given the project "Project testing the JSON API" has a "Single ended sequencing" quota of 10
    And I have already made a "Single ended sequencing" request within the study "Study testing the JSON API" for the project "Project testing the JSON API"
    And all assets have sequential UUIDs based on "aaaaaaaa-1111-2222-3333"
    Given user "abc" owns all requests
     And all requests have a priority flag

    When I retrieve the JSON for the last request in the study "Study testing the JSON API"
    Then ignoring "((source_asset|target_asset|project|study|submission)_(internal_id|barcode)|id|updated_at)" the JSON should be:
      """
      {
        "request": {
          "uuid": "22222222-2222-3333-4444-100000000000",
          "state": "pending",

          "request_type": "Single ended sequencing",
          "created_at": "2010-09-16T16:15:00+01:00",

          "project_uuid": "11111111-2222-3333-4444-ffffffffffff",
          "project_url": "http://localhost:3000/0_5/projects/11111111-2222-3333-4444-ffffffffffff",
          "project_name": "Project testing the JSON API",

          "study_uuid": "22222222-2222-3333-4444-ffffffffffff",
          "study_url": "http://localhost:3000/0_5/studies/22222222-2222-3333-4444-ffffffffffff",
          "study_name": "Study testing the JSON API",
            "submission_uuid": "11111111-2222-3333-4444-111111111111",
            "submission_url": "http://localhost:3000/0_5/submissions/11111111-2222-3333-4444-111111111111",

          "source_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000001",
          "source_asset_name": "Study testing the JSON API - Source asset",
          "source_asset_state": "",
          "source_asset_type": "library_tubes",
          "source_asset_closed": false,
          "source_asset_two_dimensional_barcode": null,

          "target_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000002",
          "target_asset_two_dimensional_barcode": null,
          "target_asset_name": "Study testing the JSON API - Target asset",
          "target_asset_type": "library_tubes",
          "target_asset_state": "",
          "target_asset_closed": false,

          "source_asset_barcode_prefix": "DN",
          "target_asset_barcode_prefix": "DN",
          "fragment_size_required_to": "21",
          "fragment_size_required_from": "1",

          "read_length": 76,

          "priority": 1,
          "user": "abc",

          "source_asset_barcode": "ignored in test because it varies uncontrollably",
          "target_asset_barcode": "ignored in test because it varies uncontrollably",

          "id": "ignored in test because it varies uncontrollably & you should use uuid instead",
          "target_asset_internal_id": "ignored in test because it varies uncontrollably & you should use target_asset_uuid instead",
          "project_internal_id": "ignored in test because it varies uncontrollably & you should use project_uuid instead",
          "source_asset_internal_id": "ignored in test because it varies uncontrollably & you should use source_asset_uuid instead",
          "study_internal_id": "ignored in test because it varies uncontrollably & you should use study_uuid instead"
        }
      }
      """
  @aliquot
  Scenario: Retrieving the JSON for a request with multiple aliquots
    And I have a sample tube called "Tube"
    And the sample tube "Tube" has been involved in a "Pulldown library creation" request within the study "Study testing the JSON API" for the project "Project testing the JSON API"
    And the sample tube "Tube" has 4 aliquots
    And all assets have sequential UUIDs based on "aaaaaaaa-1111-2222-3333"
    And all samples have sequential UUIDs based on "bbbbbbbb-1111-2222-3333"

    When I retrieve the JSON for all requests related to the sample tube "Tube"
    Then ignoring "^((source_asset.*|target_asset.*|project|study|submission)_(internal_id|barcode)|id|updated_at)" the JSON should be:
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
            "created_at": "2010-09-16T16:15:00+01:00",
            "source_asset_two_dimensional_barcode": null,
            "target_asset_type": "sample_tubes",
            "project_uuid": "11111111-2222-3333-4444-ffffffffffff",
            "study_name": "Study testing the JSON API",
            "user": "abc123",
            "target_asset_two_dimensional_barcode": null,
            "source_asset_closed": false,
            "target_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000002",
            "source_asset_uuid": "aaaaaaaa-1111-2222-3333-000000000001",
            "study_url": "http://localhost:3000/0_5/studies/22222222-2222-3333-4444-ffffffffffff",
            "project_url": "http://localhost:3000/0_5/projects/11111111-2222-3333-4444-ffffffffffff",
            "project_name": "Project testing the JSON API",
            "study_uuid": "22222222-2222-3333-4444-ffffffffffff",
            "submission_uuid": "11111111-2222-3333-4444-111111111111",
            "submission_url": "http://localhost:3000/0_5/submissions/11111111-2222-3333-4444-111111111111",
            "target_asset_sample_uuid": "bbbbbbbb-1111-2222-3333-000000000003",
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
            "source_asset_internal_id": "ignored in test because it varies uncontrollably & you should use source_asset_uuid instead",
            "source_asset_sample_internal_id": "ignored in test because it varies uncontrollably & you should use source_asset_sample_uuid instead",
            "study_internal_id": "ignored in test because it varies uncontrollably & you should use study_uuid instead"
          }
        }
      ]
      """
