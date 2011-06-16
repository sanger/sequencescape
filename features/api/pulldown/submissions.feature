@api @json @pulldown @submission_template @submission @single-sign-on @new-api @barcode-service
Feature: Creating submissions for pulldown
  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given I have an "active" study called "Testing submission creation"
      And the UUID for the study "Testing submission creation" is "22222222-3333-4444-5555-000000000000"

    Given I have a project called "Testing submission creation"
      And the UUID for the project "Testing submission creation" is "22222222-3333-4444-5555-000000000001"

    Given the plate barcode webservice returns "1000001"

    Given a "Pulldown stock plate" plate called "Testing the pulldown submissions" exists
      And all of the wells on the plate "Testing the pulldown submissions" are in an asset group called "Testing the pulldown submissions" owned by the study "Testing submission creation"
      And the UUID for the asset group "Testing the pulldown submissions" is "88888888-1111-2222-3333-000000000000"

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"

  @create
  Scenario Outline: A submission for a pulldown pipeline that uses bait libraries
    Given the UUID for the submission template "<pipeline> - HiSeq paired end sequencing" is "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/submissions":
      """
      {
        "submission": {
          "project": "22222222-3333-4444-5555-000000000001",
          "study": "22222222-3333-4444-5555-000000000000",
          "asset_group_name": "Testing the pulldown submissions",
          "request_options": {
            "read_length": 100,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            },
            "bait_library": "SureSelect Human all exon 50MB"
          }
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "submit": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/submit"
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
          }
        }
      }
      """

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      {
        "submission": {
        }
      }
      """
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "state": "pending"
        }
      }
      """

    # Check that all of the library creation requests have the correct information on them
    Given all pending delayed jobs have been processed
    Then all "<pipeline>" requests should have the following details:
      | fragment_size_required_from | 100                            |
      | fragment_size_required_to   | 200                            |
      | bait_library.name           | SureSelect Human all exon 50MB |

    Scenarios:
      | pipeline     |
      | Pulldown SC  |
      | Pulldown ISC |

  @create
  Scenario: A submission for pulldown whole genome shotgun
    Given the UUID for the submission template "Pulldown WGS - HiSeq paired end sequencing" is "00000000-1111-2222-3333-444444444444"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/submissions":
      """
      {
        "submission": {
          "project": "22222222-3333-4444-5555-000000000001",
          "study": "22222222-3333-4444-5555-000000000000",
          "asset_group_name": "Testing the pulldown submissions",
          "request_options": {
            "read_length": 100,
            "fragment_size_required": {
              "from": 100,
              "to": 200
            }
          }
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555",
            "submit": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555/submit"
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
          }
        }
      }
      """

    When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      {
        "submission": {
        }
      }
      """
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "submission": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-555555555555"
          },

          "state": "pending"
        }
      }
      """

    # Check that all of the library creation requests have the correct information on them
    Given all pending delayed jobs have been processed
    Then all "Pulldown WGS" requests should have the following details:
      | fragment_size_required_from | 100            |
      | fragment_size_required_to   | 200            |

