@api @json @submission @mutiple_orders @order @barcode-service @single-sign-on @new-api
Feature: Creating a submissin with many orders

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API

    Given I have an "active" study called "Study A"
    And the UUID for the study "Study A" is "22222222-3333-4444-5555-000000000000"

    Given I have an "active" study called "Study B"
    And the UUID for the study "Study B" is "22222222-3333-4444-5555-111111111111"

    Given plate "1234567" with 3 samples in study "Study A" exists
    Given plate "1234567" has nonzero concentration results

    Given plate "2345678" with 3 samples in study "Study B" exists
    Given plate "2345678" has nonzero concentration results

    Given I have a project called "Project A"
    And the UUID for the project "Project A" is "22222222-3333-4444-5555-000000000001"
    And project "Project A" has enough quotas

    Given I have a project called "Project B"
    And the UUID for the project "Project B" is "22222222-3333-4444-5555-000000000002"
    And project "Project B" has enough quotas

    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

  Scenario Outline: Creating a submission with multiple orders
    Given 4 <asset_type> exist with names based on "assettype"
    And all <asset_type> have sequential UUIDs based on "33333333-4444-5555-6666"
    Given the UUID for the order template "<template_name>" is "00000000-1111-2222-3333-444444444444"
    Given I have an order created with the following details based on the template "<template_name>":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000001, 33333333-4444-5555-6666-000000000002                                 |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

    Given the UUID of the next order created will be "11111111-2222-3333-4444-666666666667"
    Given I have an order created with the following details based on the template "<template_name>":
      | study           | 22222222-3333-4444-5555-111111111111                                                                       |
      | project         | 22222222-3333-4444-5555-000000000002                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000003, 33333333-4444-5555-6666-000000000004                                 |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

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
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" should have <number> "<type>" requests
    Examples:
       | template_name                                                  | number  | type                  | asset_type   |
       | Library creation - Paired end sequencing                       | 4       | Paired end sequencing | sample tubes |
       | Multiplexed Library creation - Paired end sequencing           | 2       | Paired end sequencing | sample tubes |
       | Pulldown Multiplex Library Preparation - Paired end sequencing | 2       | Paired end sequencing | wells        |

