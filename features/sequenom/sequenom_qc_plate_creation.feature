@sequenom @sequenom_creation @barcode-service
Feature: Sequenom QC Plate Creation

  I want to create a 384 Well Plate from 4 stock dilution Plates.
  The barcode of the new QC plate will be based on the barcode labels from up to 4 working dilution plates.
  NB. printing barcode labels is currently very slow as new dummy plates are create for each label.
  So if you're not specifically testing the number of labels printed limit it to 1 for speed reasons.

  Background:
    Given the "96 Well Plate" barcode printer "xyz" exists
      And today's date is "4 Aug 2010"
      And user "jack" exists with barcode "ID100I"

  @slow
  Scenario Outline: Creating a Sequenome plate from Stock Dilution Plates.
    Given the plate barcode webservice returns "<barcodes>"

    Given I am logged in as "john"
      And I am setup for sequenome QC using plates "<plate_1> <plate_2> <plate_3> <plate_4>"
      And I am on the new Sequenom QC Plate page
      And I should see "Create Sequenom Plate"
      And I should see "Input Plate Barcodes"

    When I fill in "User barcode" with "2470000100730"
      And I fill in "Plate 1" with "<plate_1>"
      And I fill in "Plate 2" with "<plate_2>"
      And I fill in "Plate 3" with "<plate_3>"
      And I fill in "Plate 4" with "<plate_4>"
      And I fill in "Number of Plates" with "<number_of_plates>"
      And select "<plate_type>" from "Plate Type"
      And select "xyz" from "Barcode Printer"



    When I press "Create new Plate"
    Then exactly <number_of_plates> labels should have been printed
      And all pending delayed jobs are processed
    Then I should see "Sequenom <plate_type> Plate <plate_type><plate_1_human>_<plate_2_human>_<plate_3_human>_<plate_4_human>_20100804 successfully created"
      And I should see "labels printed"
      And I should be on the new Sequenom QC Plate page
      And plate "1234567" should have a size of 384
      And well "A1" should come from well "A1" on plate "<plate_1>"
      And well "A2" should come from well "A1" on plate "<plate_2>"
      And well "B1" should come from well "A1" on plate "<plate_3>"
      And well "B2" should come from well "A1" on plate "<plate_4>"
      And well "A3" should come from well "A2" on plate "<plate_1>"
      And well "A4" should come from well "A2" on plate "<plate_2>"
      And well "B3" should come from well "A2" on plate "<plate_3>"
      And well "B4" should come from well "A2" on plate "<plate_4>"
    Given I am on the events page for the last sequenom plate
    Then the events table should be:
      | Message                | Content    | Created by | Created at                |
      | Created Sequenom plate | 2010-08-04 | jack       | Wednesday 04 August, 2010 |

    Examples:
      | plate_type  | plate_1       | plate_1_human | plate_2       | plate_2_human | plate_3       | plate_3_human | plate_4       | plate_4_human | number_of_plates | barcodes         |
      | QC          | 1220125054743 | 125054        |               |               |               |               |               |               | 2                | 1234567..1234568 |
      | QC          | 1220125054743 | 125054        | 1220125056761 | 125056        |               |               |               |               | 1                | 1234567          |
      | QC          | 1220125054743 | 125054        | 1220125056761 | 125056        | 1220125069815 | 125069        |               |               | 1                | 1234567          |
      | Replication | 1220125054743 | 125054        | 1220125056761 | 125056        | 1220125069815 | 125069        | 1220125048766 | 125048        | 1                | 1234567          |
      | QC          |               |               | 1220125056761 | 125056        |               |               | 1220125048766 | 125048        | 1                | 1234567          |
      | QC          |               |               | 1220125056761 | 125056        |               |               |               |               | 1                | 1234567          |
      | QC          | 1220125054743 | 125054        | 1220125054743 | 125054        | 1220125054743 | 125054        | 1220125054743 | 125054        | 1                | 1234567          |

  Scenario: User doesnt scan their barcode
    Given I am logged in as "john"
      And the plate barcode webservice returns "1234567"
      And I am setup for sequenome QC using plates "1220125054743"
      And I am on the new Sequenom QC Plate page
    When I fill in "Plate 1" with "1220125054743"
      And I press "Create new Plate"
    Then I should see "Please scan your user barcode"


  Scenario: Where Input Plate barcodes can't be found in the system.
    Given the plate barcode webservice returns "1234567"

    Given I am logged in as "john"
    Given I am on the new Sequenom QC Plate page
      And I fill in "Plate 1" with "SOMETHING_NOT_A_BAR_CODE"
      And I press "Create new Plate"
    Then I should see "Source Plate: SOMETHING_NOT_A_BAR_CODE cannot be found"

  Scenario: When no source plates are entered
    Given the plate barcode webservice returns "1234567"

    Given I am logged in as "john"
    Given I am on the new Sequenom QC Plate page
      And I press "Create new Plate"
    Then I should see "At least one source input plate barcode must be entered"


  Scenario: Where Input Plate barcodes can't be found in the system.
    Given the plate barcode webservice returns "1234567"

    Given I am an "slf_manager" user logged in as "john"
    Given I am on the new Sequenom QC Plate page
      And I fill in "Plate 1" with "SOMETHING_NOT_A_BAR_CODE"
      And I check "Bypass Source Plate Gender Checks?"
      And I press "Create new Plate"
    Then I should see "Source Plate: SOMETHING_NOT_A_BAR_CODE cannot be found"


  Scenario Outline: Source Plate Gender checking
    Given the plate barcode webservice returns "<barcodes>"

    Given I am a "<user_role>" user logged in as "<user_name>"
      And I have a source plate which contains samples which have no gender information
      And I am on the new Sequenom QC Plate page
      And I <see_or_check_bypass> "Bypass Source Plate Gender Checks?"
    When I try to create a Sequenom QC plate from the input plate
    Then I <positive_result> see "Sequenom QC Plate QC125054____20100804 successfully created"
      And I <negative_result> see "Failed to create Sequenom QC Plate - Source Plate: 1220125054743 lacks gender information"

    Examples:
       | user_role     | user_name | see_or_check_bypass | positive_result | negative_result | barcodes         |
       | internal      | bloggs    | should not see      | should not      | should          | 1234567          |
       | administrator | andrew    | uncheck             | should not      | should          | 1234567          |
       | administrator | andrew    | check               | should          | should not      | 1234567..1234568 |
       | slf_manager   | andrew    | uncheck             | should not      | should          | 1234567          |
       | slf_manager   | andrew    | check               | should          | should not      | 1234567..1234568 |
