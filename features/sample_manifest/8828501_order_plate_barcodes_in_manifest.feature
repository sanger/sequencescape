@sample @manifest @barcode-service
Feature: Order plates in a sample manifest by barcode
Also print out the barcodes in the same order as they appear in the manifest

  Background:
    Given I am an "External" user logged in as "john"
    And the configuration exists for creating sample manifest Excel spreadsheets
    And the "96 Well Plate" barcode printer "xyz" exists
      And the plate barcode webservice returns "SQPD-666"
      And the plate barcode webservice returns "SQPD-222"
      And the plate barcode webservice returns "SQPD-555"

    Given a supplier called "Test supplier name" exists
    And I have an active study called "Test study"
    Given the study "Test study" has a abbreviation
    And user "john" is a "manager" of study "Test study"
    And the study have a workflow
    Given I am visiting study "Test study" homepage
    Then I should see "Test study"
    When I follow "Sample Manifests"
    Then I should see "Create manifest for plates"

    Scenario: Out of order barcodes should be sorted in the manifest
      When I follow "Create manifest for plates"
       And I select "Default Plate" from "Template"
       And I select "Test study" from "Study"
       And I select "Test supplier name" from "Supplier"
       And I select "xyz" from "Barcode printer"
        And I fill in "Plates required" with "3"
        And I press "Create manifest and print labels"
      Then I should see "Download Blank Manifest"
      Then the last created sample manifest should be:
        | SANGER PLATE ID | WELL |
        | SQPD-222             | A1   |
        | SQPD-222             | B1   |
        | SQPD-222             | C1   |
        | SQPD-222             | D1   |
        | SQPD-222             | E1   |
        | SQPD-222             | F1   |
        | SQPD-222             | G1   |
        | SQPD-222             | H1   |
        | SQPD-222             | A2   |
        | SQPD-222             | B2   |
        | SQPD-222             | C2   |
        | SQPD-222             | D2   |
        | SQPD-222             | E2   |
        | SQPD-222             | F2   |
        | SQPD-222             | G2   |
        | SQPD-222             | H2   |
        | SQPD-222             | A3   |
        | SQPD-222             | B3   |
        | SQPD-222             | C3   |
        | SQPD-222             | D3   |
        | SQPD-222             | E3   |
        | SQPD-222             | F3   |
        | SQPD-222             | G3   |
        | SQPD-222             | H3   |
        | SQPD-222             | A4   |
        | SQPD-222             | B4   |
        | SQPD-222             | C4   |
        | SQPD-222             | D4   |
        | SQPD-222             | E4   |
        | SQPD-222             | F4   |
        | SQPD-222             | G4   |
        | SQPD-222             | H4   |
        | SQPD-222             | A5   |
        | SQPD-222             | B5   |
        | SQPD-222             | C5   |
        | SQPD-222             | D5   |
        | SQPD-222             | E5   |
        | SQPD-222             | F5   |
        | SQPD-222             | G5   |
        | SQPD-222             | H5   |
        | SQPD-222             | A6   |
        | SQPD-222             | B6   |
        | SQPD-222             | C6   |
        | SQPD-222             | D6   |
        | SQPD-222             | E6   |
        | SQPD-222             | F6   |
        | SQPD-222             | G6   |
        | SQPD-222             | H6   |
        | SQPD-222             | A7   |
        | SQPD-222             | B7   |
        | SQPD-222             | C7   |
        | SQPD-222             | D7   |
        | SQPD-222             | E7   |
        | SQPD-222             | F7   |
        | SQPD-222             | G7   |
        | SQPD-222             | H7   |
        | SQPD-222             | A8   |
        | SQPD-222             | B8   |
        | SQPD-222             | C8   |
        | SQPD-222             | D8   |
        | SQPD-222             | E8   |
        | SQPD-222             | F8   |
        | SQPD-222             | G8   |
        | SQPD-222             | H8   |
        | SQPD-222             | A9   |
        | SQPD-222             | B9   |
        | SQPD-222             | C9   |
        | SQPD-222             | D9   |
        | SQPD-222             | E9   |
        | SQPD-222             | F9   |
        | SQPD-222             | G9   |
        | SQPD-222             | H9   |
        | SQPD-222             | A10  |
        | SQPD-222             | B10  |
        | SQPD-222             | C10  |
        | SQPD-222             | D10  |
        | SQPD-222             | E10  |
        | SQPD-222             | F10  |
        | SQPD-222             | G10  |
        | SQPD-222             | H10  |
        | SQPD-222             | A11  |
        | SQPD-222             | B11  |
        | SQPD-222             | C11  |
        | SQPD-222             | D11  |
        | SQPD-222             | E11  |
        | SQPD-222             | F11  |
        | SQPD-222             | G11  |
        | SQPD-222             | H11  |
        | SQPD-222             | A12  |
        | SQPD-222             | B12  |
        | SQPD-222             | C12  |
        | SQPD-222             | D12  |
        | SQPD-222             | E12  |
        | SQPD-222             | F12  |
        | SQPD-222             | G12  |
        | SQPD-222             | H12  |
        | SQPD-555             | A1   |
        | SQPD-555             | B1   |
        | SQPD-555             | C1   |
        | SQPD-555             | D1   |
        | SQPD-555             | E1   |
        | SQPD-555             | F1   |
        | SQPD-555             | G1   |
        | SQPD-555             | H1   |
        | SQPD-555             | A2   |
        | SQPD-555             | B2   |
        | SQPD-555             | C2   |
        | SQPD-555             | D2   |
        | SQPD-555             | E2   |
        | SQPD-555             | F2   |
        | SQPD-555             | G2   |
        | SQPD-555             | H2   |
        | SQPD-555             | A3   |
        | SQPD-555             | B3   |
        | SQPD-555             | C3   |
        | SQPD-555             | D3   |
        | SQPD-555             | E3   |
        | SQPD-555             | F3   |
        | SQPD-555             | G3   |
        | SQPD-555             | H3   |
        | SQPD-555             | A4   |
        | SQPD-555             | B4   |
        | SQPD-555             | C4   |
        | SQPD-555             | D4   |
        | SQPD-555             | E4   |
        | SQPD-555             | F4   |
        | SQPD-555             | G4   |
        | SQPD-555             | H4   |
        | SQPD-555             | A5   |
        | SQPD-555             | B5   |
        | SQPD-555             | C5   |
        | SQPD-555             | D5   |
        | SQPD-555             | E5   |
        | SQPD-555             | F5   |
        | SQPD-555             | G5   |
        | SQPD-555             | H5   |
        | SQPD-555             | A6   |
        | SQPD-555             | B6   |
        | SQPD-555             | C6   |
        | SQPD-555             | D6   |
        | SQPD-555             | E6   |
        | SQPD-555             | F6   |
        | SQPD-555             | G6   |
        | SQPD-555             | H6   |
        | SQPD-555             | A7   |
        | SQPD-555             | B7   |
        | SQPD-555             | C7   |
        | SQPD-555             | D7   |
        | SQPD-555             | E7   |
        | SQPD-555             | F7   |
        | SQPD-555             | G7   |
        | SQPD-555             | H7   |
        | SQPD-555             | A8   |
        | SQPD-555             | B8   |
        | SQPD-555             | C8   |
        | SQPD-555             | D8   |
        | SQPD-555             | E8   |
        | SQPD-555             | F8   |
        | SQPD-555             | G8   |
        | SQPD-555             | H8   |
        | SQPD-555             | A9   |
        | SQPD-555             | B9   |
        | SQPD-555             | C9   |
        | SQPD-555             | D9   |
        | SQPD-555             | E9   |
        | SQPD-555             | F9   |
        | SQPD-555             | G9   |
        | SQPD-555             | H9   |
        | SQPD-555             | A10  |
        | SQPD-555             | B10  |
        | SQPD-555             | C10  |
        | SQPD-555             | D10  |
        | SQPD-555             | E10  |
        | SQPD-555             | F10  |
        | SQPD-555             | G10  |
        | SQPD-555             | H10  |
        | SQPD-555             | A11  |
        | SQPD-555             | B11  |
        | SQPD-555             | C11  |
        | SQPD-555             | D11  |
        | SQPD-555             | E11  |
        | SQPD-555             | F11  |
        | SQPD-555             | G11  |
        | SQPD-555             | H11  |
        | SQPD-555             | A12  |
        | SQPD-555             | B12  |
        | SQPD-555             | C12  |
        | SQPD-555             | D12  |
        | SQPD-555             | E12  |
        | SQPD-555             | F12  |
        | SQPD-555             | G12  |
        | SQPD-555             | H12  |
        | SQPD-666             | A1   |
        | SQPD-666             | B1   |
        | SQPD-666             | C1   |
        | SQPD-666             | D1   |
        | SQPD-666             | E1   |
        | SQPD-666             | F1   |
        | SQPD-666             | G1   |
        | SQPD-666             | H1   |
        | SQPD-666             | A2   |
        | SQPD-666             | B2   |
        | SQPD-666             | C2   |
        | SQPD-666             | D2   |
        | SQPD-666             | E2   |
        | SQPD-666             | F2   |
        | SQPD-666             | G2   |
        | SQPD-666             | H2   |
        | SQPD-666             | A3   |
        | SQPD-666             | B3   |
        | SQPD-666             | C3   |
        | SQPD-666             | D3   |
        | SQPD-666             | E3   |
        | SQPD-666             | F3   |
        | SQPD-666             | G3   |
        | SQPD-666             | H3   |
        | SQPD-666             | A4   |
        | SQPD-666             | B4   |
        | SQPD-666             | C4   |
        | SQPD-666             | D4   |
        | SQPD-666             | E4   |
        | SQPD-666             | F4   |
        | SQPD-666             | G4   |
        | SQPD-666             | H4   |
        | SQPD-666             | A5   |
        | SQPD-666             | B5   |
        | SQPD-666             | C5   |
        | SQPD-666             | D5   |
        | SQPD-666             | E5   |
        | SQPD-666             | F5   |
        | SQPD-666             | G5   |
        | SQPD-666             | H5   |
        | SQPD-666             | A6   |
        | SQPD-666             | B6   |
        | SQPD-666             | C6   |
        | SQPD-666             | D6   |
        | SQPD-666             | E6   |
        | SQPD-666             | F6   |
        | SQPD-666             | G6   |
        | SQPD-666             | H6   |
        | SQPD-666             | A7   |
        | SQPD-666             | B7   |
        | SQPD-666             | C7   |
        | SQPD-666             | D7   |
        | SQPD-666             | E7   |
        | SQPD-666             | F7   |
        | SQPD-666             | G7   |
        | SQPD-666             | H7   |
        | SQPD-666             | A8   |
        | SQPD-666             | B8   |
        | SQPD-666             | C8   |
        | SQPD-666             | D8   |
        | SQPD-666             | E8   |
        | SQPD-666             | F8   |
        | SQPD-666             | G8   |
        | SQPD-666             | H8   |
        | SQPD-666             | A9   |
        | SQPD-666             | B9   |
        | SQPD-666             | C9   |
        | SQPD-666             | D9   |
        | SQPD-666             | E9   |
        | SQPD-666             | F9   |
        | SQPD-666             | G9   |
        | SQPD-666             | H9   |
        | SQPD-666             | A10  |
        | SQPD-666             | B10  |
        | SQPD-666             | C10  |
        | SQPD-666             | D10  |
        | SQPD-666             | E10  |
        | SQPD-666             | F10  |
        | SQPD-666             | G10  |
        | SQPD-666             | H10  |
        | SQPD-666             | A11  |
        | SQPD-666             | B11  |
        | SQPD-666             | C11  |
        | SQPD-666             | D11  |
        | SQPD-666             | E11  |
        | SQPD-666             | F11  |
        | SQPD-666             | G11  |
        | SQPD-666             | H11  |
        | SQPD-666             | A12  |
        | SQPD-666             | B12  |
        | SQPD-666             | C12  |
        | SQPD-666             | D12  |
        | SQPD-666             | E12  |
        | SQPD-666             | F12  |
        | SQPD-666             | G12  |
        | SQPD-666             | H12  |
