@api @json @single-sign-on @new-api @bait_library @barcode-service
Feature: Assigning bait libraries to a plate
  The bait libraries are actually assigned based on the submission from the user but to provide client
  applications with the ability to preview this information it is (optionally) a two-step process.

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
      And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

    Given a user with UUID "99999999-8888-7777-6666-555555555555" exists

    Given the UUID for the search "Find assets by barcode" is "33333333-4444-5555-6666-000000000001"

    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"

    Given transfers between "SC stock DNA" and "SC hyb" plates are done by "Transfer" requests

    # Setup the plates so that they flow appropriately.  This is a bit of a cheat in that it's only
    # a direct link and that we're faking out the pipeline work but it suffices.
    Given a "SC stock DNA" plate called "Testing bait libraries" exists
      And all wells on the plate "Testing bait libraries" have unique samples
      And the UUID for the plate "Testing bait libraries" is "00000000-1111-2222-3333-000000000001"

    Given "A1-H6" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Pulldown SC - HiSeq Paired end sequencing" with the following request options:
      | read_length       | 100                 |
      | bait_library_name | Human all exon 50MB |

    Given "A7-H12" of the plate with UUID "00000000-1111-2222-3333-000000000001" have been submitted to "Pulldown SC - HiSeq Paired end sequencing" with the following request options:
      | read_length       | 100            |
      | bait_library_name | Mouse all exon |

    Given a "SC hyb" plate called "Target for bait libraries" exists as a child of "Testing bait libraries"
      And the "Transfer columns 1-12" transfer template has been used between "Testing bait libraries" and "Target for bait libraries"
      And the UUID for the plate "Target for bait libraries" is "00000000-1111-2222-3333-000000000002"

  Scenario: Previewing the assignment of the bait libraries
    When I make an authorised POST with the following JSON to the API path "/bait_library_layouts/preview":
      """
      {
        "bait_library_layout": {
          "user": "99999999-8888-7777-6666-555555555555",
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
            "A1":  "Human all exon 50MB",
            "A2":  "Human all exon 50MB",
            "A3":  "Human all exon 50MB",
            "A4":  "Human all exon 50MB",
            "A5":  "Human all exon 50MB",
            "A6":  "Human all exon 50MB",
            "A7":  "Mouse all exon",
            "A8":  "Mouse all exon",
            "A9":  "Mouse all exon",
            "A10": "Mouse all exon",
            "A11": "Mouse all exon",
            "A12": "Mouse all exon",

            "B1":  "Human all exon 50MB",
            "B2":  "Human all exon 50MB",
            "B3":  "Human all exon 50MB",
            "B4":  "Human all exon 50MB",
            "B5":  "Human all exon 50MB",
            "B6":  "Human all exon 50MB",
            "B7":  "Mouse all exon",
            "B8":  "Mouse all exon",
            "B9":  "Mouse all exon",
            "B10": "Mouse all exon",
            "B11": "Mouse all exon",
            "B12": "Mouse all exon",

            "C1":  "Human all exon 50MB",
            "C2":  "Human all exon 50MB",
            "C3":  "Human all exon 50MB",
            "C4":  "Human all exon 50MB",
            "C5":  "Human all exon 50MB",
            "C6":  "Human all exon 50MB",
            "C7":  "Mouse all exon",
            "C8":  "Mouse all exon",
            "C9":  "Mouse all exon",
            "C10": "Mouse all exon",
            "C11": "Mouse all exon",
            "C12": "Mouse all exon",

            "D1":  "Human all exon 50MB",
            "D2":  "Human all exon 50MB",
            "D3":  "Human all exon 50MB",
            "D4":  "Human all exon 50MB",
            "D5":  "Human all exon 50MB",
            "D6":  "Human all exon 50MB",
            "D7":  "Mouse all exon",
            "D8":  "Mouse all exon",
            "D9":  "Mouse all exon",
            "D10": "Mouse all exon",
            "D11": "Mouse all exon",
            "D12": "Mouse all exon",

            "E1":  "Human all exon 50MB",
            "E2":  "Human all exon 50MB",
            "E3":  "Human all exon 50MB",
            "E4":  "Human all exon 50MB",
            "E5":  "Human all exon 50MB",
            "E6":  "Human all exon 50MB",
            "E7":  "Mouse all exon",
            "E8":  "Mouse all exon",
            "E9":  "Mouse all exon",
            "E10": "Mouse all exon",
            "E11": "Mouse all exon",
            "E12": "Mouse all exon",

            "F1":  "Human all exon 50MB",
            "F2":  "Human all exon 50MB",
            "F3":  "Human all exon 50MB",
            "F4":  "Human all exon 50MB",
            "F5":  "Human all exon 50MB",
            "F6":  "Human all exon 50MB",
            "F7":  "Mouse all exon",
            "F8":  "Mouse all exon",
            "F9":  "Mouse all exon",
            "F10": "Mouse all exon",
            "F11": "Mouse all exon",
            "F12": "Mouse all exon",

            "G1":  "Human all exon 50MB",
            "G2":  "Human all exon 50MB",
            "G3":  "Human all exon 50MB",
            "G4":  "Human all exon 50MB",
            "G5":  "Human all exon 50MB",
            "G6":  "Human all exon 50MB",
            "G7":  "Mouse all exon",
            "G8":  "Mouse all exon",
            "G9":  "Mouse all exon",
            "G10": "Mouse all exon",
            "G11": "Mouse all exon",
            "G12": "Mouse all exon",

            "H1":  "Human all exon 50MB",
            "H2":  "Human all exon 50MB",
            "H3":  "Human all exon 50MB",
            "H4":  "Human all exon 50MB",
            "H5":  "Human all exon 50MB",
            "H6":  "Human all exon 50MB",
            "H7":  "Mouse all exon",
            "H8":  "Mouse all exon",
            "H9":  "Mouse all exon",
            "H10": "Mouse all exon",
            "H11": "Mouse all exon",
            "H12": "Mouse all exon"
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
          "user": "99999999-8888-7777-6666-555555555555",
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
            "A1":  "Human all exon 50MB",
            "A2":  "Human all exon 50MB",
            "A3":  "Human all exon 50MB",
            "A4":  "Human all exon 50MB",
            "A5":  "Human all exon 50MB",
            "A6":  "Human all exon 50MB",
            "A7":  "Mouse all exon",
            "A8":  "Mouse all exon",
            "A9":  "Mouse all exon",
            "A10": "Mouse all exon",
            "A11": "Mouse all exon",
            "A12": "Mouse all exon",

            "B1":  "Human all exon 50MB",
            "B2":  "Human all exon 50MB",
            "B3":  "Human all exon 50MB",
            "B4":  "Human all exon 50MB",
            "B5":  "Human all exon 50MB",
            "B6":  "Human all exon 50MB",
            "B7":  "Mouse all exon",
            "B8":  "Mouse all exon",
            "B9":  "Mouse all exon",
            "B10": "Mouse all exon",
            "B11": "Mouse all exon",
            "B12": "Mouse all exon",

            "C1":  "Human all exon 50MB",
            "C2":  "Human all exon 50MB",
            "C3":  "Human all exon 50MB",
            "C4":  "Human all exon 50MB",
            "C5":  "Human all exon 50MB",
            "C6":  "Human all exon 50MB",
            "C7":  "Mouse all exon",
            "C8":  "Mouse all exon",
            "C9":  "Mouse all exon",
            "C10": "Mouse all exon",
            "C11": "Mouse all exon",
            "C12": "Mouse all exon",

            "D1":  "Human all exon 50MB",
            "D2":  "Human all exon 50MB",
            "D3":  "Human all exon 50MB",
            "D4":  "Human all exon 50MB",
            "D5":  "Human all exon 50MB",
            "D6":  "Human all exon 50MB",
            "D7":  "Mouse all exon",
            "D8":  "Mouse all exon",
            "D9":  "Mouse all exon",
            "D10": "Mouse all exon",
            "D11": "Mouse all exon",
            "D12": "Mouse all exon",

            "E1":  "Human all exon 50MB",
            "E2":  "Human all exon 50MB",
            "E3":  "Human all exon 50MB",
            "E4":  "Human all exon 50MB",
            "E5":  "Human all exon 50MB",
            "E6":  "Human all exon 50MB",
            "E7":  "Mouse all exon",
            "E8":  "Mouse all exon",
            "E9":  "Mouse all exon",
            "E10": "Mouse all exon",
            "E11": "Mouse all exon",
            "E12": "Mouse all exon",

            "F1":  "Human all exon 50MB",
            "F2":  "Human all exon 50MB",
            "F3":  "Human all exon 50MB",
            "F4":  "Human all exon 50MB",
            "F5":  "Human all exon 50MB",
            "F6":  "Human all exon 50MB",
            "F7":  "Mouse all exon",
            "F8":  "Mouse all exon",
            "F9":  "Mouse all exon",
            "F10": "Mouse all exon",
            "F11": "Mouse all exon",
            "F12": "Mouse all exon",

            "G1":  "Human all exon 50MB",
            "G2":  "Human all exon 50MB",
            "G3":  "Human all exon 50MB",
            "G4":  "Human all exon 50MB",
            "G5":  "Human all exon 50MB",
            "G6":  "Human all exon 50MB",
            "G7":  "Mouse all exon",
            "G8":  "Mouse all exon",
            "G9":  "Mouse all exon",
            "G10": "Mouse all exon",
            "G11": "Mouse all exon",
            "G12": "Mouse all exon",

            "H1":  "Human all exon 50MB",
            "H2":  "Human all exon 50MB",
            "H3":  "Human all exon 50MB",
            "H4":  "Human all exon 50MB",
            "H5":  "Human all exon 50MB",
            "H6":  "Human all exon 50MB",
            "H7":  "Mouse all exon",
            "H8":  "Mouse all exon",
            "H9":  "Mouse all exon",
            "H10": "Mouse all exon",
            "H11": "Mouse all exon",
            "H12": "Mouse all exon"
          }
        }
      }
      """

    # Check that the bait libraries have been properly assigned to the wells of the plate
    Then the bait library for "A1-H6" of the plate "Target for bait libraries" should be "Human all exon 50MB"
     And the bait library for "A7-H12" of the plate "Target for bait libraries" should be "Mouse all exon"

