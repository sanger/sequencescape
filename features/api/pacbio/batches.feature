@api @json @batch @single-sign-on @new-api @pacbio @authorised @wip
Feature: PacBio behaviour through the API

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have an "active" study called "Testing PacBio batch study"
    And the UUID for the study "Testing PacBio batch study" is "22222222-3333-4444-5555-000000000000"

    Given I have a project called "Testing PacBio batch project"
    And the UUID for the project "Testing PacBio batch project" is "22222222-3333-4444-5555-000000000001"

    Given 2 sample tubes exist with names based on "pacbio_sample_tube"
    And all sample tubes have sequential UUIDs based on "88888888-1111-2222-3333"

    Given I have a submission created with the following details based on the template "PacBio":
      | study           | 22222222-3333-4444-5555-000000000000                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                       |
      | request_options | "insert_size": 250, sequencing_type: Standard                                |
      | assets          | 88888888-1111-2222-3333-000000000001, 88888888-1111-2222-3333-000000000002 |
    And the last submission wants 10 runs of the "PacBio Sequencing" requests
    And the last submission has been submitted
    And all pending delayed jobs are processed
    And all requests have sequential UUIDs based on "99999999-1111-2222-3333"

    Given all requests for the "PacBio Sample Prep" pipeline are in a batch
    And the UUID for the last batch is "00000000-1111-2222-3333-444444444444"
    And all PacBio library tubes have sequential UUIDs based on "88888888-2222-3333-4444"

  @update @request
  Scenario Outline: Setting the number of SMRT cells available causes requests to be cancelled
    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "batch": {
          "state": "started",

          "requests": [
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "target_asset": {
                "smrt_cells_available": <smrt cells available>
              }
            }
          ]
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "started",
          "requests": [ 
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "state": "started"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000012",
              "state": "started"
            }
          ]
        }
      }
      """

    Then <downstream cancellations> of the downstream requests from the "PacBio Sample Prep" pipeline of the request with UUID "99999999-1111-2222-3333-000000000001" should be "cancelled"

    Examples:
      | smrt cells available | downstream cancellations |
      | 10                   | 0                        |
      | 2                    | 8                        |
      | 0                    | 10                       |

  @update @request
  Scenario: Failing a request causes downstream requests to be cancelled
    When I make an authorised PUT with the following JSON to the API path "/00000000-1111-2222-3333-444444444444":
      """
      {
        "batch": {
          "state": "started",

          "requests": [
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "state": "failed"
            }
          ]
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "batch": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444",
            "update": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "state": "started",
          "requests": [ 
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "state": "failed"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000012",
              "state": "started"
            }
          ]
        }
      }
      """

    Then all of the downstream requests from the "PacBio Sample Prep" pipeline of the request with UUID "99999999-1111-2222-3333-000000000001" should be "cancelled"
