@api @json @submission @mutiple_orders @order @barcode-service @single-sign-on @new-api
Feature: Creating a submissin with many orders

  Background:
    Given I have a WGS submission template
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

    Given I have an "active" study called "Study A"
    And the UUID for the study "Study A" is "22222222-3333-4444-5555-000000000000"

    Given I have an "active" study called "Study B"
    And the UUID for the study "Study B" is "22222222-3333-4444-5555-111111111111"

    Given I have a project called "Project A"
    And the UUID for the project "Project A" is "22222222-3333-4444-5555-000000000001"

    Given I have a project called "Project B"
    And the UUID for the project "Project B" is "22222222-3333-4444-5555-000000000002"

    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

  Scenario: Creating a submission with multiple orders
    Given there is a 96 well "Cherrypicked" plate with a barcode of "1220012345855"
    And all wells have sequential UUIDs based on "33333333-4444-5555-6666"
    Given the UUID for the order template "Illumina-B - Pooled PATH - HiSeq Paired end sequencing" is "00000000-1111-2222-3333-444444444444"
    Given I have an order created with the following details based on the template "Illumina-B - Pooled PATH - HiSeq Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000001, 33333333-4444-5555-6666-000000000002                                 |
      | request_options | read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    Given the UUID of the next order created will be "11111111-2222-3333-4444-666666666667"
    Given I have an order created with the following details based on the template "Illumina-B - Pooled PATH - HiSeq Paired end sequencing":
      | study           | 22222222-3333-4444-5555-111111111111                                                                       |
      | project         | 22222222-3333-4444-5555-000000000002                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000003, 33333333-4444-5555-6666-000000000004                                 |
      | request_options | read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    When I POST the following JSON to the API path "/submissions":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666",
            "11111111-2222-3333-4444-666666666667"
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
          "orders": [
            { "uuid": "11111111-2222-3333-4444-666666666666" },
            { "uuid": "11111111-2222-3333-4444-666666666667" }
          ]
        }
      }
      """
     When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666"
          ]
        }
      }
      """
    Then the HTTP response should be "200 OK"
    Given all pending delayed jobs are processed
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" should have 1 "Illumina-B HiSeq Paired end sequencing" requests
