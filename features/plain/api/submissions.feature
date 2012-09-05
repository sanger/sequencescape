@api @json @submission @allow-rescue @submission_api
Feature: Interacting with submissions through the API
  Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"

    Given I am using version "0_5" of a legacy API


    Given I have an "active" study called "Testing submission creation"
    And the UUID for the study "Testing submission creation" is "22222222-3333-4444-5555-000000000000"

    Given I have a project called "Testing submission creation"
    And the UUID for the project "Testing submission creation" is "22222222-3333-4444-5555-000000000001"

    Given the UUID for the submission template "Library creation - Paired end sequencing" is "00000000-1111-2222-3333-444444444444"
    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

    Given the UUID for the request type "Library creation" is "99999999-1111-2222-3333-000000000000"
    And the UUID for the request type "Paired end sequencing" is "99999999-1111-2222-3333-000000000001"


  Scenario: Listing all of the submissions that exist if there aren't any
    When I GET the API path "/submissions"
    Then the JSON should be an empty array

  Scenario: Retrieving the JSON for a submission that does not exist
    When I GET the API path "/submissions/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"

  Scenario: Retrieving the JSON for a particular submission with 3 assets
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
      And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Library creation - Paired end sequencing":
      | study   | 22222222-3333-4444-5555-000000000000 |
      | project | 22222222-3333-4444-5555-000000000001 |
      | assets  | 33333333-4444-5555-6666-000000000001,33333333-4444-5555-6666-000000000002,33333333-4444-5555-6666-000000000003 |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      And the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission

    When I GET the API path "/orders/11111111-2222-3333-4444-666666666666"
    Then ignoring "updated_at|internal_id" the JSON should be:
      """
            {
          "order":
          {
            "uuid": "11111111-2222-3333-4444-666666666666",
            "created_at": "2010-09-16T13:45:00+01:00",
            "created_by": "abc123",
            "template_name":"Library creation - Paired end sequencing",
            "study_name": "Testing submission creation",
            "study_uuid": "22222222-3333-4444-5555-000000000000",
            "project_name": "Testing submission creation",
            "project_uuid": "22222222-3333-4444-5555-000000000001",
            "submission_uuid": "11111111-2222-3333-4444-555555555555",
            "asset_uuids": [
              "33333333-4444-5555-6666-000000000001",
              "33333333-4444-5555-6666-000000000002",
              "33333333-4444-5555-6666-000000000003"
            ],
            "request_options":
            {
              "read_length": 76,
              "fragment_size_required":
              {
                "from": 100,
                "to": 200
              },
             "library_type": "qPCR only"
            }
          }
         }
      """
    When I GET the API path "/submissions/11111111-2222-3333-4444-555555555555"
    Then ignoring "updated_at|internal_id" the JSON should be:
      """
        {
          "submission":
          {
            "uuid": "11111111-2222-3333-4444-555555555555",
            "created_at": "2010-09-16T13:45:00+01:00",
            "created_by": "abc123",
            "state": "building",
            "study_name": "Testing submission creation",
            "study_uuid": "22222222-3333-4444-5555-000000000000",
            "project_name": "Testing submission creation",
            "project_uuid": "22222222-3333-4444-5555-000000000001",
            "orders": "http://localhost:3000/0_5/submissions/11111111-2222-3333-4444-555555555555/orders"
          }
        }
      """

  Scenario: Retrieving the JSON for a submission with request options
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
      And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    Given I have an order created with the following details based on the template "Library creation - Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000001                                                                       |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |
      And the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission

    When I GET the API path "/orders/11111111-2222-3333-4444-666666666666"
    Then ignoring "updated_at|internal_id" the JSON should be:
      """
        {
          "order":
          {
            "uuid": "11111111-2222-3333-4444-666666666666",
            "created_at": "2010-09-16T13:45:00+01:00",
            "created_by": "abc123",
            "template_name":"Library creation - Paired end sequencing",
            "study_name": "Testing submission creation",
            "study_uuid": "22222222-3333-4444-5555-000000000000",
            "project_name": "Testing submission creation",
            "project_uuid": "22222222-3333-4444-5555-000000000001",
            "submission_uuid": "11111111-2222-3333-4444-555555555555",
            "asset_uuids": [  "33333333-4444-5555-6666-000000000001" ],
            "request_options":
            {
              "read_length": 76,
              "fragment_size_required":
              {
                "from": 100,
                "to": 200
              },
             "library_type": "qPCR only"
            }
          }
        }
      """
    When I GET the API path "/submissions/11111111-2222-3333-4444-555555555555"
    Then ignoring "updated_at|internal_id" the JSON should be:
      """
        {
          "submission":
          {
            "uuid": "11111111-2222-3333-4444-555555555555",
            "created_at": "2010-09-16T13:45:00+01:00",
            "created_by": "abc123",
            "state": "building",
            "study_name": "Testing submission creation",
            "study_uuid": "22222222-3333-4444-5555-000000000000",
            "project_name": "Testing submission creation",
            "project_uuid": "22222222-3333-4444-5555-000000000001",
            "orders": "http://localhost:3000/0_5/submissions/11111111-2222-3333-4444-555555555555/orders"
          }
        }
      """
