@api @json @single-sign-on @new-api @bait_library @barcode-service
Feature: Assigning bait libraries to a plate
  The bait libraries are actually assigned based on the submission from the user but to provide client
  applications with the ability to preview this information it is (optionally) a two-step process.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given the UUID for the search "Find asset by barcode" is "33333333-4444-5555-6666-000000000001"

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    # Setup the plates so that they flow appropriately.  This is a bit of a cheat in that it's only
    # a direct link and that we're faking out the pipeline work but it suffices.
    Given a "Pulldown stock plate" plate called "Testing bait libraries" exists
      And all wells on the plate "Testing bait libraries" have unique samples
      And the UUID for the plate "Testing bait libraries" is "00000000-1111-2222-3333-000000000001"

    Given a "SC hybridisation plate" plate called "Target for bait libraries" exists
      And the "Transfer columns 1-12" transfer template has been used between "Testing bait libraries" and "Target for bait libraries"
      And the UUID for the plate "Target for bait libraries" is "00000000-1111-2222-3333-000000000002"

    # Make a submission of the stock plate so that we can define the bait libraries.  We make two
    # distinct submissions here in order to check that the right bait libraries are assigned.
    Given "A1-H6" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Pulldown SC - HiSeq Paired end sequencing" with the following request options:
      | read_length                 | 100                            |
      | fragment_size_required_from | 100                            |
      | fragment_size_required_to   | 200                            |
      | bait_library_name           | SureSelect Human all exon 50MB |

    Given "A7-H12" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Pulldown SC - HiSeq Paired end sequencing" with the following request options:
      | read_length                 | 100                            |
      | fragment_size_required_from | 100                            |
      | fragment_size_required_to   | 200                            |
      | bait_library_name           | SureSelect Mouse all exon 50MB |

  Scenario: Previewing the assignment of the bait libraries
    When I make an authorised POST with the following JSON to the API path "/bait_library_layouts/preview":
      """
      {
        "bait_library_layout": {
          "plate": "00000000-1111-2222-3333-000000000002"
        }
      }
      """
    Then the HTTP response should be "200 OK"
     And the JSON should match the following for the specified fields:
      """
      {
        "bait_library_layout": {
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "layout": {
            "A1":  "SureSelect Human all exon 50MB",
            "A2":  "SureSelect Human all exon 50MB",
            "A3":  "SureSelect Human all exon 50MB",
            "A4":  "SureSelect Human all exon 50MB",
            "A5":  "SureSelect Human all exon 50MB",
            "A6":  "SureSelect Human all exon 50MB",
            "A7":  "SureSelect Mouse all exon 50MB",
            "A8":  "SureSelect Mouse all exon 50MB",
            "A9":  "SureSelect Mouse all exon 50MB",
            "A10": "SureSelect Mouse all exon 50MB",
            "A11": "SureSelect Mouse all exon 50MB",
            "A12": "SureSelect Mouse all exon 50MB",

            "B1":  "SureSelect Human all exon 50MB",
            "B2":  "SureSelect Human all exon 50MB",
            "B3":  "SureSelect Human all exon 50MB",
            "B4":  "SureSelect Human all exon 50MB",
            "B5":  "SureSelect Human all exon 50MB",
            "B6":  "SureSelect Human all exon 50MB",
            "B7":  "SureSelect Mouse all exon 50MB",
            "B8":  "SureSelect Mouse all exon 50MB",
            "B9":  "SureSelect Mouse all exon 50MB",
            "B10": "SureSelect Mouse all exon 50MB",
            "B11": "SureSelect Mouse all exon 50MB",
            "B12": "SureSelect Mouse all exon 50MB",

            "C1":  "SureSelect Human all exon 50MB",
            "C2":  "SureSelect Human all exon 50MB",
            "C3":  "SureSelect Human all exon 50MB",
            "C4":  "SureSelect Human all exon 50MB",
            "C5":  "SureSelect Human all exon 50MB",
            "C6":  "SureSelect Human all exon 50MB",
            "C7":  "SureSelect Mouse all exon 50MB",
            "C8":  "SureSelect Mouse all exon 50MB",
            "C9":  "SureSelect Mouse all exon 50MB",
            "C10": "SureSelect Mouse all exon 50MB",
            "C11": "SureSelect Mouse all exon 50MB",
            "C12": "SureSelect Mouse all exon 50MB",

            "D1":  "SureSelect Human all exon 50MB",
            "D2":  "SureSelect Human all exon 50MB",
            "D3":  "SureSelect Human all exon 50MB",
            "D4":  "SureSelect Human all exon 50MB",
            "D5":  "SureSelect Human all exon 50MB",
            "D6":  "SureSelect Human all exon 50MB",
            "D7":  "SureSelect Mouse all exon 50MB",
            "D8":  "SureSelect Mouse all exon 50MB",
            "D9":  "SureSelect Mouse all exon 50MB",
            "D10": "SureSelect Mouse all exon 50MB",
            "D11": "SureSelect Mouse all exon 50MB",
            "D12": "SureSelect Mouse all exon 50MB",

            "E1":  "SureSelect Human all exon 50MB",
            "E2":  "SureSelect Human all exon 50MB",
            "E3":  "SureSelect Human all exon 50MB",
            "E4":  "SureSelect Human all exon 50MB",
            "E5":  "SureSelect Human all exon 50MB",
            "E6":  "SureSelect Human all exon 50MB",
            "E7":  "SureSelect Mouse all exon 50MB",
            "E8":  "SureSelect Mouse all exon 50MB",
            "E9":  "SureSelect Mouse all exon 50MB",
            "E10": "SureSelect Mouse all exon 50MB",
            "E11": "SureSelect Mouse all exon 50MB",
            "E12": "SureSelect Mouse all exon 50MB",

            "F1":  "SureSelect Human all exon 50MB",
            "F2":  "SureSelect Human all exon 50MB",
            "F3":  "SureSelect Human all exon 50MB",
            "F4":  "SureSelect Human all exon 50MB",
            "F5":  "SureSelect Human all exon 50MB",
            "F6":  "SureSelect Human all exon 50MB",
            "F7":  "SureSelect Mouse all exon 50MB",
            "F8":  "SureSelect Mouse all exon 50MB",
            "F9":  "SureSelect Mouse all exon 50MB",
            "F10": "SureSelect Mouse all exon 50MB",
            "F11": "SureSelect Mouse all exon 50MB",
            "F12": "SureSelect Mouse all exon 50MB",

            "G1":  "SureSelect Human all exon 50MB",
            "G2":  "SureSelect Human all exon 50MB",
            "G3":  "SureSelect Human all exon 50MB",
            "G4":  "SureSelect Human all exon 50MB",
            "G5":  "SureSelect Human all exon 50MB",
            "G6":  "SureSelect Human all exon 50MB",
            "G7":  "SureSelect Mouse all exon 50MB",
            "G8":  "SureSelect Mouse all exon 50MB",
            "G9":  "SureSelect Mouse all exon 50MB",
            "G10": "SureSelect Mouse all exon 50MB",
            "G11": "SureSelect Mouse all exon 50MB",
            "G12": "SureSelect Mouse all exon 50MB",

            "H1":  "SureSelect Human all exon 50MB",
            "H2":  "SureSelect Human all exon 50MB",
            "H3":  "SureSelect Human all exon 50MB",
            "H4":  "SureSelect Human all exon 50MB",
            "H5":  "SureSelect Human all exon 50MB",
            "H6":  "SureSelect Human all exon 50MB",
            "H7":  "SureSelect Mouse all exon 50MB",
            "H8":  "SureSelect Mouse all exon 50MB",
            "H9":  "SureSelect Mouse all exon 50MB",
            "H10": "SureSelect Mouse all exon 50MB",
            "H11": "SureSelect Mouse all exon 50MB",
            "H12": "SureSelect Mouse all exon 50MB"
          }
        }
      }
      """
    Then there should be no bait library layouts

  Scenario: Assigning bait libraries
    When I make an authorised POST with the following JSON to the API path "/bait_library_layouts":
      """
      {
        "bait_library_layout": {
          "plate": "00000000-1111-2222-3333-000000000002"
        }
      }
      """
    Then the HTTP response should be "201 Created"
     And the JSON should match the following for the specified fields:
      """
      {
        "bait_library_layout": {
          "plate": {
            "actions": {
              "read": "http://www.example.com/api/1/00000000-1111-2222-3333-000000000002"
            }
          },
          "layout": {
            "A1":  "SureSelect Human all exon 50MB",
            "A2":  "SureSelect Human all exon 50MB",
            "A3":  "SureSelect Human all exon 50MB",
            "A4":  "SureSelect Human all exon 50MB",
            "A5":  "SureSelect Human all exon 50MB",
            "A6":  "SureSelect Human all exon 50MB",
            "A7":  "SureSelect Mouse all exon 50MB",
            "A8":  "SureSelect Mouse all exon 50MB",
            "A9":  "SureSelect Mouse all exon 50MB",
            "A10": "SureSelect Mouse all exon 50MB",
            "A11": "SureSelect Mouse all exon 50MB",
            "A12": "SureSelect Mouse all exon 50MB",

            "B1":  "SureSelect Human all exon 50MB",
            "B2":  "SureSelect Human all exon 50MB",
            "B3":  "SureSelect Human all exon 50MB",
            "B4":  "SureSelect Human all exon 50MB",
            "B5":  "SureSelect Human all exon 50MB",
            "B6":  "SureSelect Human all exon 50MB",
            "B7":  "SureSelect Mouse all exon 50MB",
            "B8":  "SureSelect Mouse all exon 50MB",
            "B9":  "SureSelect Mouse all exon 50MB",
            "B10": "SureSelect Mouse all exon 50MB",
            "B11": "SureSelect Mouse all exon 50MB",
            "B12": "SureSelect Mouse all exon 50MB",

            "C1":  "SureSelect Human all exon 50MB",
            "C2":  "SureSelect Human all exon 50MB",
            "C3":  "SureSelect Human all exon 50MB",
            "C4":  "SureSelect Human all exon 50MB",
            "C5":  "SureSelect Human all exon 50MB",
            "C6":  "SureSelect Human all exon 50MB",
            "C7":  "SureSelect Mouse all exon 50MB",
            "C8":  "SureSelect Mouse all exon 50MB",
            "C9":  "SureSelect Mouse all exon 50MB",
            "C10": "SureSelect Mouse all exon 50MB",
            "C11": "SureSelect Mouse all exon 50MB",
            "C12": "SureSelect Mouse all exon 50MB",

            "D1":  "SureSelect Human all exon 50MB",
            "D2":  "SureSelect Human all exon 50MB",
            "D3":  "SureSelect Human all exon 50MB",
            "D4":  "SureSelect Human all exon 50MB",
            "D5":  "SureSelect Human all exon 50MB",
            "D6":  "SureSelect Human all exon 50MB",
            "D7":  "SureSelect Mouse all exon 50MB",
            "D8":  "SureSelect Mouse all exon 50MB",
            "D9":  "SureSelect Mouse all exon 50MB",
            "D10": "SureSelect Mouse all exon 50MB",
            "D11": "SureSelect Mouse all exon 50MB",
            "D12": "SureSelect Mouse all exon 50MB",

            "E1":  "SureSelect Human all exon 50MB",
            "E2":  "SureSelect Human all exon 50MB",
            "E3":  "SureSelect Human all exon 50MB",
            "E4":  "SureSelect Human all exon 50MB",
            "E5":  "SureSelect Human all exon 50MB",
            "E6":  "SureSelect Human all exon 50MB",
            "E7":  "SureSelect Mouse all exon 50MB",
            "E8":  "SureSelect Mouse all exon 50MB",
            "E9":  "SureSelect Mouse all exon 50MB",
            "E10": "SureSelect Mouse all exon 50MB",
            "E11": "SureSelect Mouse all exon 50MB",
            "E12": "SureSelect Mouse all exon 50MB",

            "F1":  "SureSelect Human all exon 50MB",
            "F2":  "SureSelect Human all exon 50MB",
            "F3":  "SureSelect Human all exon 50MB",
            "F4":  "SureSelect Human all exon 50MB",
            "F5":  "SureSelect Human all exon 50MB",
            "F6":  "SureSelect Human all exon 50MB",
            "F7":  "SureSelect Mouse all exon 50MB",
            "F8":  "SureSelect Mouse all exon 50MB",
            "F9":  "SureSelect Mouse all exon 50MB",
            "F10": "SureSelect Mouse all exon 50MB",
            "F11": "SureSelect Mouse all exon 50MB",
            "F12": "SureSelect Mouse all exon 50MB",

            "G1":  "SureSelect Human all exon 50MB",
            "G2":  "SureSelect Human all exon 50MB",
            "G3":  "SureSelect Human all exon 50MB",
            "G4":  "SureSelect Human all exon 50MB",
            "G5":  "SureSelect Human all exon 50MB",
            "G6":  "SureSelect Human all exon 50MB",
            "G7":  "SureSelect Mouse all exon 50MB",
            "G8":  "SureSelect Mouse all exon 50MB",
            "G9":  "SureSelect Mouse all exon 50MB",
            "G10": "SureSelect Mouse all exon 50MB",
            "G11": "SureSelect Mouse all exon 50MB",
            "G12": "SureSelect Mouse all exon 50MB",

            "H1":  "SureSelect Human all exon 50MB",
            "H2":  "SureSelect Human all exon 50MB",
            "H3":  "SureSelect Human all exon 50MB",
            "H4":  "SureSelect Human all exon 50MB",
            "H5":  "SureSelect Human all exon 50MB",
            "H6":  "SureSelect Human all exon 50MB",
            "H7":  "SureSelect Mouse all exon 50MB",
            "H8":  "SureSelect Mouse all exon 50MB",
            "H9":  "SureSelect Mouse all exon 50MB",
            "H10": "SureSelect Mouse all exon 50MB",
            "H11": "SureSelect Mouse all exon 50MB",
            "H12": "SureSelect Mouse all exon 50MB"
          }
        }
      }
      """

    # Check that the bait libraries have been properly assigned to the wells of the plate
    Then the bait library for "A1-H6" of the plate "Target for bait libraries" should be "SureSelect Human all exon 50MB"
     And the bait library for "A7-H12" of the plate "Target for bait libraries" should be "SureSelect Mouse all exon 50MB"

