@api @json @submission @mutiple_orders @order @barcode-service @single-sign-on @new-api
Feature: Pre-capture pools should be defined at submission

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

  Scenario: Creating a submission with multiple orders
    And all wells have sequential UUIDs based on "33333333-4444-5555-6666"
    Given the UUID for the order template "Illumina-A - HTP ISC - Single ended sequencing" is "00000000-1111-2222-3333-444444444444"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"
    Given I have an order created with the following details based on the template "Illumina-A - HTP ISC - Single ended sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000001, 33333333-4444-5555-6666-000000000013                                 |
      | request_options | library_type: Agilent Pulldown, fragment_size_required_from: 100, fragment_size_required_to: 200, pre_capture_plex_level: 1,bait_library_name: Human all exon 50MB, read_length: 54|
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666667"
    Given I have an order created with the following details based on the template "Illumina-A - HTP ISC - Single ended sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000025, 33333333-4444-5555-6666-000000000037, 33333333-4444-5555-6666-000000000049                                |
      | pre_cap_group   | 1                                                                                                          |
      | request_options | library_type: Agilent Pulldown, fragment_size_required_from: 100, fragment_size_required_to: 200, pre_capture_plex_level: 2,bait_library_name: Human all exon 50MB, read_length: 54|
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666668"
    Given I have an order created with the following details based on the template "Illumina-A - HTP ISC - Single ended sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000061, 33333333-4444-5555-6666-000000000073                                 |
      | pre_cap_group   | 1                                                                                                          |
      | request_options | library_type: Agilent Pulldown, fragment_size_required_from: 100, fragment_size_required_to: 200, pre_capture_plex_level: 2,bait_library_name: Human all exon 50MB, read_length: 54|
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666669"
    Given I have an order created with the following details based on the template "Illumina-A - HTP ISC - Single ended sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                       |
      | project         | 22222222-3333-4444-5555-000000000001                                                                       |
      | assets          | 33333333-4444-5555-6666-000000000002, 33333333-4444-5555-6666-000000000014, 33333333-4444-5555-6666-000000000085 |
      | request_options | library_type: Agilent Pulldown, fragment_size_required_from: 100, fragment_size_required_to: 200, pre_capture_plex_level: 2,bait_library_name: Human all exon 50MB, read_length: 54|

    When I POST the following JSON to the API path "/submissions":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666","11111111-2222-3333-4444-666666666667",
            "11111111-2222-3333-4444-666666666668","11111111-2222-3333-4444-666666666669"
          ]
        }
      }
      """
     Then I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666","11111111-2222-3333-4444-666666666667",
            "11111111-2222-3333-4444-666666666668","11111111-2222-3333-4444-666666666669"
          ]
        }
      }
      """
    Given all pending delayed jobs are processed
    Then there should be 7 pre capture pools
    And the wells should be pooled in column order for 53788839


