@json @api @pico @barcode-service @pico_set_results
Feature: Upload Pico Green concentration results from the Pico Green application
  # TODO Break this background down to use factories.  As it is it's too slow!
  Background:
    Given I am logged in as "user"
    And the "96 Well Plate" barcode printer "xyz" exists
    And the plate barcode webservice returns "1234567"
    Given all of this is happening at exactly "14-Feb-2011 23:00:00+01:00"
    Given a plate with purpose "Pico Standard" and barcode "1234567" exists

  @qc_event @study_report @qc_study_report
  Scenario: upload concentration results from the pico application
    Given a stock plate with barcode "1221234567841" exists
    And plate "1234567" has "96" wells with aliquots
    # Create pico standard, dilution and pico assay plates.
    # NOTE: We have to create the "Pico Standard" in this manner as it relies on the barcode service being
    # up and running, which appears not to be the case for backgrounds (oddly).
    And the "Working dilution" plate is created from the plate with barcode "1221234567841"
    And the "Pico dilution" plate is created from the plate with barcode "6251234567836"
    And the "Pico Assay Plates" plate is created from the plate with barcode "4361234567667"

    When I post the JSON below to update the plate:
      """
      {
          "pico_set_result": {
              "wells": [{
                "well": {
                  "concentration": 43.9496,
                  "map": "A1"
                }
              },
              {
                "well": {
                  "concentration": 23.4,
                  "map": "H12"
                }
              }],
              "assay_barcode": "4331234567653",
              "state": "passed"
          }
      }
      """
    Then well "A1" on plate "1221234567841" should have a concentration of 43.9496
    And well "H12" on plate "1221234567841" should have a concentration of 23.4
    Then the plate "1221234567841" should have a 'pico_analysed' event
    And well "A1" on plate "1221234567841" should have a 'pico_analysed' event
    And well "H12" on plate "1221234567841" should have a 'pico_analysed' event

    Given I have an active study called "Test study"
    Given plate "1221234567841" is part of study "Test study"
    Given I am on the Qc reports homepage
    Then I should see "New report for"
    When I select "Test study" from "Study"
    And I press "Submit"
    Given 1 pending delayed jobs are processed
    And I am on the Qc reports homepage
    Then I follow "Download report for Test study"
    Then I should see the report for "Test study":
    | Pico     | Well | Pico date  |
    | Pass     | A1   | 2011-02-14 |
    | ungraded | A2   |            |
    | ungraded | A3   |            |
    | ungraded | A4   |            |
    | ungraded | A5   |            |
    | ungraded | A6   |            |
    | ungraded | A7   |            |
    | ungraded | A8   |            |
    | ungraded | A9   |            |
    | ungraded | A10  |            |
    | ungraded | A11  |            |
    | ungraded | A12  |            |
    | ungraded | B1   |            |
    | ungraded | B2   |            |
    | ungraded | B3   |            |
    | ungraded | B4   |            |
    | ungraded | B5   |            |
    | ungraded | B6   |            |
    | ungraded | B7   |            |
    | ungraded | B8   |            |
    | ungraded | B9   |            |
    | ungraded | B10  |            |
    | ungraded | B11  |            |
    | ungraded | B12  |            |
    | ungraded | C1   |            |
    | ungraded | C2   |            |
    | ungraded | C3   |            |
    | ungraded | C4   |            |
    | ungraded | C5   |            |
    | ungraded | C6   |            |
    | ungraded | C7   |            |
    | ungraded | C8   |            |
    | ungraded | C9   |            |
    | ungraded | C10  |            |
    | ungraded | C11  |            |
    | ungraded | C12  |            |
    | ungraded | D1   |            |
    | ungraded | D2   |            |
    | ungraded | D3   |            |
    | ungraded | D4   |            |
    | ungraded | D5   |            |
    | ungraded | D6   |            |
    | ungraded | D7   |            |
    | ungraded | D8   |            |
    | ungraded | D9   |            |
    | ungraded | D10  |            |
    | ungraded | D11  |            |
    | ungraded | D12  |            |
    | ungraded | E1   |            |
    | ungraded | E2   |            |
    | ungraded | E3   |            |
    | ungraded | E4   |            |
    | ungraded | E5   |            |
    | ungraded | E6   |            |
    | ungraded | E7   |            |
    | ungraded | E8   |            |
    | ungraded | E9   |            |
    | ungraded | E10  |            |
    | ungraded | E11  |            |
    | ungraded | E12  |            |
    | ungraded | F1   |            |
    | ungraded | F2   |            |
    | ungraded | F3   |            |
    | ungraded | F4   |            |
    | ungraded | F5   |            |
    | ungraded | F6   |            |
    | ungraded | F7   |            |
    | ungraded | F8   |            |
    | ungraded | F9   |            |
    | ungraded | F10  |            |
    | ungraded | F11  |            |
    | ungraded | F12  |            |
    | ungraded | G1   |            |
    | ungraded | G2   |            |
    | ungraded | G3   |            |
    | ungraded | G4   |            |
    | ungraded | G5   |            |
    | ungraded | G6   |            |
    | ungraded | G7   |            |
    | ungraded | G8   |            |
    | ungraded | G9   |            |
    | ungraded | G10  |            |
    | ungraded | G11  |            |
    | ungraded | G12  |            |
    | ungraded | H1   |            |
    | ungraded | H2   |            |
    | ungraded | H3   |            |
    | ungraded | H4   |            |
    | ungraded | H5   |            |
    | ungraded | H6   |            |
    | ungraded | H7   |            |
    | ungraded | H8   |            |
    | ungraded | H9   |            |
    | ungraded | H10  |            |
    | ungraded | H11  |            |
    | Pass     | H12  | 2011-02-14 |



  Scenario Outline: Changing the Pico Pass state of the wells on a Pico Plate
    Given a stock plate with barcode "1221234567841" exists
    And plate "1234567" has "1" wells
    # Create pico standard, dilution and pico assay plates.
    # NOTE: We have to create the "Pico Standard" in this manner as it relies on the barcode service being
    # up and running, which appears not to be the case for backgrounds (oddly).
    And the "Pico dilution" plate is created from the plate with barcode "1221234567841"
    And the "Pico Assay Plates" plate is created from the plate with barcode "4361234567667"
    Given the Stock Plate's Pico pass state is set to "<INITIAL_STOCK_STATE>"
    When I post the JSON below to update the plate:
      """
      {
          "pico_set_result": {
              "wells": [{
                "well": {
                  "concentration": 43.9496,
                  "map": "A1"
                }
              }],
              "assay_barcode": "4331234567653",
              "state": "<JSON_STATE_MESSAGE>"
          }
      }
      """
    Then the Stock Plate's Pico pass state is "<FINISH_STATE>"

    Examples:
      | INITIAL_STOCK_STATE | JSON_STATE_MESSAGE | FINISH_STATE |
      |                     | passed             | Pass         |
      | ungraded            | passed             | Pass         |
      | ungraded            | failed             | Repeat       |
      | Repeat              | failed             | Fail         |
      | Repeat              | passed             | Pass         |
      | Fail                | failed             | Fail         |
      | Fail                | passed             | Pass         |
      | Pass                | passed             | Pass         |

