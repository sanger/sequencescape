@sequenom @sequenom_creation @barcode-service
Feature: Sequenom QC Plates
 I want to view the details of sequenome plates created

  Background:
    Given I am logged in as "user"
    And today's date is "4 Aug 2010"
    And a plate barcode webservice is available and returns "1234567"
    And the "96 Well Plate" barcode printer "xyz" exists
    Given I have an active study called "Study A"
    And I have an active study called "Study B"
    And user "jack" exists with barcode "ID100I"

  Scenario: Display the details of a sequenome plate
    Given I have created a sequenom plate
    And plate "125054" has 1 blank samples
    And plate "125056" has 0 blank samples
    And plate "125069" has 0 blank samples
    And plate "125048" has 3 blank samples
    Given I am on the sequenom qc home page

    Then the table of sequenom plates should be:
      | Plate      | Name in MSPEC                          | Created    | Quadrant | Source Plate | No. Blanks | Study   | Type             | A1 Name         |
      | DN1234567T | QC125054_125056_125069_125048_20100804 | 2010-08-04 | 1        | 125054       | 1          | Study A | Working Dilution | 125054_0        |
      | DN1234567T | QC125054_125056_125069_125048_20100804 | 2010-08-04 | 2        | 125056       | 0          | Study A | Working Dilution | 1220125056761_x |
      | DN1234567T | QC125054_125056_125069_125048_20100804 | 2010-08-04 | 3        | 125069       | 0          | Study B | Stock Plate      | 1220125069815_x |
      | DN1234567T | QC125054_125056_125069_125048_20100804 | 2010-08-04 | 4        | 125048       | 3          | Study B | Stock Plate      | 125048_0        |



