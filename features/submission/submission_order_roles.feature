@api @json @submission @mutiple_orders @order @barcode-service @single-sign-on @new-api
Feature: Submission templates should set order roles

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given I have an "active" study called "Study A"
    And the UUID for the study "Study A" is "22222222-3333-4444-5555-000000000000"

    Given there is a 96 well "Cherrypicked" plate with a barcode of "1220012345855"

    Given I have a project called "Project A"
    And the UUID for the project "Project A" is "22222222-3333-4444-5555-000000000001"

    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

  Scenario Outline: Creating a submission with multiple orders
    And all <asset_type> have sequential UUIDs based on "33333333-4444-5555-6666"
    Given the UUID for the order template "<template_name>" is "00000000-1111-2222-3333-444444444444"
    Given I have an order created with the following details based on the template "<template_name>":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000001, 33333333-4444-5555-6666-000000000002                                 |
      | request_options | read_length: 76, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: qPCR only |

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
     Then I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666"
          ]
        }
      }
      """
    Given all pending delayed jobs are processed
    Then the plate with the barcode "12345" should have a label of "<label>"
    Examples:
       | template_name                                               | asset_type   | label    |
       | Illumina-B - Pooled PATH - Paired end sequencing | wells        | ILB PATH |
       | Illumina-B - Pooled HWGS - Paired end sequencing | wells        | ILB HWGS |

