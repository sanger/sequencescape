@api @json @uk10k @cancer @order @submission @single-sign-on @new-api
Feature: Full run through of the UK10K submissions
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have an "active" study called "Testing submission creation"
    And the UUID for the study "Testing submission creation" is "22222222-3333-4444-5555-000000000000"

    Given I have a project called "Testing submission creation"
    And the UUID for the project "Testing submission creation" is "22222222-3333-4444-5555-000000000001"

    Given the UUID for the order template "Library creation - Paired end sequencing" is "00000000-1111-2222-3333-444444444444"
    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

    Given the UUID for the request type "Library creation" is "99999999-1111-2222-3333-000000000000"
    And the UUID for the request type "Paired end sequencing" is "99999999-1111-2222-3333-000000000001"

  @full-workflow @create @update @submit @read
  Scenario: Create submission, attach assets, and then submit it
    Given 3 sample tubes exist with names based on "sampletube" and IDs starting at 1
    And all sample tubes have sequential UUIDs based on "33333333-4444-5555-6666"

    # Retrieving the order template ...
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "order_template": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "orders": {
            "actions": {
              "create": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/orders"
            }
          },

          "uuid": "00000000-1111-2222-3333-444444444444",
          "name": "Library creation - Paired end sequencing"
        }
      }
      """

    # Creating ...
    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/orders":
      """
      {
        "order": {
          "project": "22222222-3333-4444-5555-000000000001",
          "study": "22222222-3333-4444-5555-000000000000"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "order": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666"
          },

          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Testing submission creation"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },

          "assets": [],

          "request_types": [
            {
              "uuid": "99999999-1111-2222-3333-000000000000",
              "name": "Library creation"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "name": "Paired end sequencing"
            }
          ],
          "request_options": {}
        }
      }
      """
    And the JSON should not contain "uuids_to_ids" within any element of "order.request_types"

    # Attaching the assets and updating the details ...
    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
      """
      {
        "order": {
          "assets": [
            "33333333-4444-5555-6666-000000000001",
            "33333333-4444-5555-6666-000000000002",
            "33333333-4444-5555-6666-000000000003"
          ],
          "request_options": {
            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          }
        }
      }
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "order": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666"
          },

          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Testing submission creation"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },

          "assets": [
            { "uuid": "33333333-4444-5555-6666-000000000001" },
            { "uuid": "33333333-4444-5555-6666-000000000002" },
            { "uuid": "33333333-4444-5555-6666-000000000003" }
          ],

          "request_types": [
            {
              "uuid": "99999999-1111-2222-3333-000000000000",
              "name": "Library creation"
            },
            {
              "uuid": "99999999-1111-2222-3333-000000000001",
              "name": "Paired end sequencing"
            }
          ],
          "request_options": {
            "read_length": 76,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "library_type": "qPCR only"
          }
        }
      }
      """

    # Create a submission
    When I POST the following JSON to the API path "/submissions":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666"
          ]
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
     """
     {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },
          "state": "building",
          "orders": [
            {
              "uuid": "11111111-2222-3333-4444-666666666666"
            }
          ],
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
     }
     """

    # Submitting the submission ...
    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      """
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },
          "state": "pending",
          "orders": [
            {
              "uuid": "11111111-2222-3333-4444-666666666666"
            }
          ],
          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
      }
      """

    # Check that the submission can be processed and creates the correct information in the DB
    Given all pending delayed jobs are processed
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" is ready

    # Now reload the submission JSON to see that the state is correct ...
    Given the number of results returned by the API per page is 6
    When I GET the API path "/11111111-2222-3333-4444-555555555555"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "state": "ready",
          "orders": [
            {
              "uuid": "11111111-2222-3333-4444-666666666666"
            }
          ],

          "requests": {
            "actions": {
              "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests"
            }
          }
        }
      }
      """

    # And now we'll check that the requests are correct too ...
    # ... there should be 3 library creation "requests": one per input asset (sample tube)
    # ... there should be 3 paired end sequencing "requests": one per output asset from the above requests
    When I GET the API path "/11111111-2222-3333-4444-555555555555/requests"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "actions": {
          "last": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests/1",
          "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests/1",
          "first": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/requests/1"
        },
        "requests": [
          {
            "source_asset": {
              "uuid": "33333333-4444-5555-6666-000000000001",
              "type": "sample_tubes"
            },
            "target_asset": null,

            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Library creation",
            "library_type": "qPCR only"
          }, {
            "source_asset": {
              "uuid": "33333333-4444-5555-6666-000000000002",
              "type": "sample_tubes"
            },
            "target_asset": null,

            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Library creation",
            "library_type": "qPCR only"
          }, {
            "source_asset": {
              "uuid": "33333333-4444-5555-6666-000000000003",
              "type": "sample_tubes"
            },
            "target_asset": null,

            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Library creation",
            "library_type": "qPCR only"
          }, {
            "source_asset": null,
            "target_asset": null,

            "read_length": 76,
            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Paired end sequencing"
          }, {
            "source_asset": null,
            "target_asset": null,

            "read_length": 76,
            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Paired end sequencing"
          }, {
            "source_asset": null,
            "target_asset": null,

            "read_length": 76,
            "fragment_size": {
              "from": "100",
              "to": "200"
            },
            "type": "Paired end sequencing"
          }
        ]
      }
      """
