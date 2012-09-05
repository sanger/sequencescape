@qc @gel
Feature: Gel QC
  In order to QC a gel using plate
  As a lab user
  I want to be able to update information about gel score

  Background:
    Given I am an "slf_gel" user logged in as "john"
    And a "Stock Plate" plate purpose and of type "Plate" with barcode "1220000123724" exists
    And plate "123" has "3" wells
    And I am on the gel QC page
    Then I should see "Find gel plate"
    Given all of this is happening at exactly "14-Feb-2011 23:00:00+01:00"

  @gel_index
  Scenario: Gel dilution with working dilution and stock plate should display on index
    And a "Working Dilution" plate purpose and of type "WorkingDilutionPlate" with barcode "6250000123818" exists
    And a "Gel Dilution" plate purpose and of type "GelDilutionPlate" with barcode "1930000123708" exists
    And plate "1220000123724" is the parent of plate "6250000123818"
    And plate "6250000123818" is the parent of plate "1930000123708"
    Given I am on the gel QC page
    Then I should see "Find gel plate"

  @gel_index @qc_event
  Scenario: Gel dilution linked directly to stock plate should display on index
    And a "Working Dilution" plate purpose and of type "WorkingDilutionPlate" with barcode "6250000123818" exists
    And a "Gel Dilution" plate purpose and of type "GelDilutionPlate" with barcode "1930000123708" exists
    And plate "1220000123724" is the parent of plate "6250000123818"
    And plate "1220000123724" is the parent of plate "1930000123708"
    Given I am on the gel QC page
    Then I should see "Find gel plate"
    Then I should see "123"
    And I should not see "Rescore"

  @gel_index
  Scenario: Gel dilution with no parents should not display
    And a "Gel Dilution" plate purpose and of type "GelDilutionPlate" with barcode "1930000123708" exists
    Given I am on the gel QC page
    Then I should see "Find gel plate"
    Then I should not see "123"

  @qc_event
  Scenario: Gel dilution with score should display rescore
    And a "Working Dilution" plate purpose and of type "WorkingDilutionPlate" with barcode "6250000123818" exists
    And a "Gel Dilution" plate purpose and of type "GelDilutionPlate" with barcode "1930000123708" exists
    And all wells on plate "1220000123724" have non-empty sample names
    And plate "1220000123724" is the parent of plate "6250000123818"
    And plate "1220000123724" is the parent of plate "1930000123708"
    Given I am on the gel QC page
    Then I should see "Find gel plate"
    Then I should see "123"
    And I should not see "Rescore"
    When I follow "Score"
    And I press "Update gel values"
    When I am on the gel QC page
    Then I should see "Rescore"
    Then the plate "1220000123724" and each well should have a 'gel_analysed' event
    When I follow "123"
    And I follow "Event history"
    Then the events table should be:
      | Message      | Content    | Created by |
      | Gel Analysed | 2011-02-14 | john       |


  @study_report @qc_study_report @qc_event
  Scenario: Display gel analysed date in the study report
    And a "Working Dilution" plate purpose and of type "WorkingDilutionPlate" with barcode "6250000123818" exists
    And a "Gel Dilution" plate purpose and of type "GelDilutionPlate" with barcode "1930000123708" exists
    And all wells on plate "1220000123724" have non-empty sample names
    And plate "1220000123724" is the parent of plate "6250000123818"
    And plate "1220000123724" is the parent of plate "1930000123708"
    Given I have an active study called "Test study"
    Given plate "1220000123724" is part of study "Test study"
    Given I am on the gel QC page
    When I follow "Score"
    And I press "Update gel values"

    Given a study report is generated for study "Test study"
    Then the last report for "Test study" should be:
    | Gel | Well | Gel QC date |
    | OK  | A1   | 2011-02-14  |
    | OK  | A2   | 2011-02-14  |
    | OK  | A3   | 2011-02-14  |


  Scenario: Lookup plate where all wells have completed sample names
    Given all wells on plate "1220000123724" have non-empty sample names
    When I fill in "barcode" with "123"
    When I press "Update gel values"
    Then I should see "Plate DN123H"
    When I select "No Band" from "A1"
    When I press "Update gel values"
    Then I should see "Gel results for plate updated"
    And I should be on the gel QC page

  Scenario: Set degraded on well
    Given all wells on plate "1220000123724" have non-empty sample names
    When I fill in "barcode" with "123"
    When I press "Update gel values"
    Then I should see "Plate DN123H"
    When I select "Degraded" from "A1"
    When I press "Update gel values"
    Then I should see "Gel results for plate updated"
    And I should be on the gel QC page


  Scenario: Lookup plate where all wells have no samples
    When I fill in "barcode" with "123"
    When I press "Update gel values"
    Then I should see "Plate DN123H"
    And I should not see "No Band"

  Scenario Outline: Lookup plate where some wells have blank sample names from SNP
    Given all wells on plate "1220000123724" have non-empty sample names
    Given well "A2" on plate "1220000123724" has a sample name of "<empty_sample_name>"
    When I fill in "barcode" with "123"
    When I press "Update gel values"
    Then I should see "Plate DN123H"
    Then I should not see "Well A2"
    When I select "No Band" from "A1"
    When I press "Update gel values"
    Then I should see "Gel results for plate updated"
    And I should be on the gel QC page
    Examples:
    | empty_sample_name |
    | Water |
    | water |
    | WATER |
    | Blank |
    | |
    | empty |

@manifest
  Scenario: Lookup plate where some wells have blank sample names from an uploaded manifest
    Given all wells on plate "1220000123724" have non-empty sample names
    Given well "A2" on plate "1220000123724" has an empty supplier sample name
    When I fill in "barcode" with "123"
    When I press "Update gel values"
    Then I should see "Plate DN123H"
    Then I should not see "Well A2"
    When I select "No Band" from "A1"
    When I press "Update gel values"
    Then I should see "Gel results for plate updated"
    And I should be on the gel QC page
