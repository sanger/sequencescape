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
    Given a stock plate with barcode "1221234568855" exists
    And plate "1234567" has "2" wells with aliquots
    And plate "1234568" has "2" wells with aliquots
    # Create pico standard, dilution and pico assay plates.
    # NOTE: We have to create the "Pico Standard" in this manner as it relies on the barcode service being
    # up and running, which appears not to be the case for backgrounds (oddly).
    And the "Working dilution" plate with barcode "1234567" is created by cherrypicking "1234567" and "1234568"
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
                  "map": "A7"
                }
              }],
              "assay_barcode": "4331234567653",
              "state": "passed"
          }
      }
      """
    Then well "A1" on plate "1221234567841" should have a concentration of 43.9496
    And well "A1" on plate "1221234568855" should have a concentration of 23.4
    Then the plate "1221234567841" should have a 'pico_analysed' event
    Then the plate "1221234568855" should have a 'pico_analysed' event
    And well "A1" on plate "1221234567841" should have a 'pico_analysed' event
    And well "A1" on plate "1221234568855" should have a 'pico_analysed' event

  @qc_event @study_report @qc_study_report
  Scenario: upload negative concentration results from the pico application
    Given a stock plate with barcode "1221234567841" exists
    Given a stock plate with barcode "1221234568855" exists
    And plate "1234567" has "2" wells with aliquots
    And plate "1234568" has "2" wells with aliquots
    # Create pico standard, dilution and pico assay plates.
    # NOTE: We have to create the "Pico Standard" in this manner as it relies on the barcode service being
    # up and running, which appears not to be the case for backgrounds (oddly).
    And the "Working dilution" plate with barcode "1234567" is created by cherrypicking "1234567" and "1234568"
    And the "Pico dilution" plate is created from the plate with barcode "6251234567836"
    And the "Pico Assay Plates" plate is created from the plate with barcode "4361234567667"

    When I post the JSON below to update the plate:
      """
      {
          "pico_set_result": {
              "wells": [{
                "well": {
                  "concentration": -43.9496,
                  "map": "A1"
                }
              },
              {
                "well": {
                  "concentration": -23.4,
                  "map": "A7"
                }
              }],
              "assay_barcode": "4331234567653",
              "state": "passed"
          }
      }
      """
    Then well "A1" on plate "1221234567841" should have a concentration of 0.0
    And well "A1" on plate "1221234568855" should have a concentration of 0.0
    Then the plate "1221234567841" should have a 'pico_analysed' event
    Then the plate "1221234568855" should have a 'pico_analysed' event
    And well "A1" on plate "1221234567841" should have a 'pico_analysed' event
    And well "A1" on plate "1221234568855" should have a 'pico_analysed' event


