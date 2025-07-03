@timetravel @barcode-service @printing @slf
Feature: Printing new plate barcodes
  Background:
    Given I am logged in as "user"
    And the Baracoda barcode service returns "SQPD-1234569"
    And the "96 Well Plate" barcode printer "xyz" exists
    Given user "jack" exists with barcode "ID100I"

  Scenario: Creating plates without scanning the user barcode
    Given I am on the new plate page
    Then I should see "Create Plates"
    And I should see "Barcode printer"
    When I select "Pulldown" from "Plate purpose"
    And I select "xyz" from "Barcode printer"
    And I press "Submit"
    Then I should see "Please scan your user barcode"

  Scenario: Creating plates where the barcode service errors
    Given I am on the new plate page
    Then I should see "Create Plates"
    And I should see "Barcode printer"
    When I select "Pulldown" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    Then Pmb is down
    And I press "Submit"
    Then I should see "Barcode labels failed to print"

  @javascript
  Scenario: Creating plates where the scanner appends a carriage return
    Given I am on the new plate page
    When I fill in "User barcode" with multiline text
    """
    2470000100730

    """
    When I select "Stock Plate" from "Plate purpose"
    And I select "xyz" from "Barcode printer"
    And I select "No" from "Group results for reprinting barcodes?"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"
    And I should be on the plate page

  Scenario Outline: Creating plates
    Given I am on the new plate page
    And the Baracoda barcode service returns "SQPD-1234570"
    When I select "<plate_purpose>" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"
    And I should be on the plate page

    Examples:
      | plate_purpose       |
      | Pico Standard       |
      | Pulldown            |
      | Pico Assay Plates   |
      | Dilution Plates     |
      | Gel Dilution Plates |
      | Stock Plate         |

  Scenario Outline: Create plates only from the proper parent plate or from scratch
    Given a plate with purpose "<parent_plate_purpose>" and barcode "1221234567841" exists
    And the Baracoda barcode service returns "SQPD-1234570"
    And a plate with purpose "Cherrypicked" and barcode "1220001454858" exists
    And I am on the new plate page
    Then I should see "Create Plates"

    When I select "<plate_purpose>" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"
    And I should be on the plate page

    When I select "<plate_purpose>" from "Plate purpose"
    And I fill in the field labeled "Source plates" with "1220001454858"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And I press "Submit"
    Then I should see "Scanned plate 1220001454858 has a purpose Cherrypicked not valid"
    And I should be on the plate page

    Examples:
      | plate_purpose         | parent_plate_purpose |
      | Working dilution      | Stock Plate          |
      | Pico dilution         | Working dilution     |
      | Pico Assay Plates     | Pico dilution        |

  @xml @qc_event
  Scenario: Create all QC plates for SLF
    When I freeze time at "Mon Jul 12 10:23:58 UTC 2010"
    #Given a plate with purpose "Stock plate" and barcode "1221234567841" exists
    Given a plate with purpose "Stock plate" and barcode "SQPD-1234567" exists
    And plate "SQPD-1234567" has "7" wells with aliquots
    #And a plate with barcode "1220001454858" exists
    And a plate with barcode "SQPD-1454" exists
    And plate "SQPD-1454" has "8" wells with aliquots
    Given I am on the new plate page
    Then I should see "Create Plates"

    When I select "Pico Standard" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"

    #And the Baracoda barcode service returns "SQPD-77777"
    #And the Baracoda children barcode service for parent barcode "DN1454U" returns 1 barcode
    And the Baracoda children barcode service for parent barcode "SQPD-1454" returns 1 barcode
    #When I fill in the field labeled "Source plates" with "1220001454858"
    When I fill in the field labeled "Source plates" with "SQPD-1454"
    When I select "Stock Plate" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"

    #And the Baracoda barcode service returns "SQPD-77777"
    #And the Baracoda children barcode service for parent barcode "DN1234567T" returns 1 barcode
    And the Baracoda children barcode service for parent barcode "SQPD-1234567" returns 1 barcode
    #When I fill in the field labeled "Source plates" with "1221234567841"
    When I fill in the field labeled "Source plates" with "SQPD-1234567"
    When I select "Working dilution" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"

    #And the Baracoda barcode service returns "SQPD-77777"
    #And the Baracoda children barcode service for parent barcode "6251234567836" returns 1 barcode
    And the Baracoda children barcode service for parent barcode "SQPD-1234567-1" returns 1 barcode
    #When I fill in the field labeled "Source plates" with "6251234567836"
    When I fill in the field labeled "Source plates" with "SQPD-1234567-1"
    When I select "Pico dilution" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"

    #And the Baracoda barcode service returns "SQPD-77777"
    #And the Baracoda children barcode service for parent barcode "4361234567667" returns 1 barcode
    And the Baracoda children barcode service for parent barcode "SQPD-1234567-2" returns 2 barcodes
    #When I fill in the field labeled "Source plates" with "4361234567667"
    When I fill in the field labeled "Source plates" with "SQPD-1234567-2"
    When I select "Pico Assay Plates" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"

    #And the Baracoda barcode service returns "SQPD-77777"
    #And the Baracoda children barcode service for parent barcode "6251234567836" returns 1 barcode
    And the Baracoda children barcode service for parent barcode "SQPD-1234567-1" returns 1 barcode
    #When I fill in the field labeled "Source plates" with "6251234567836"
    When I fill in the field labeled "Source plates" with "SQPD-1234567-1"
    When I select "Gel Dilution Plates" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates successfully"
    #And plate with barcode "4331234567653" should exist
    #And plate with barcode "4341234567737" should exist
    #And plate with barcode "1931234567771" should exist
    #And plate with barcode "1220077777868" should exist
    And plate with barcode "SQPD-1234567-1" should exist
    And plate with barcode "SQPD-1234567-2" should exist
    And plate with barcode "SQPD-1234567-3" should exist
    And plate with barcode "SQPD-1234567-4" should exist
    And plate with barcode "SQPD-1234567-5" should exist
    And plate with barcode "SQPD-1454-1" should exist


    #Given I am on the events page for asset with barcode "1221234567841"
    Given I am on the events page for asset with barcode "SQPD-1234567"

    Then the events table should be:
      | Message                              | Content    | Created by | Created at           |
      | Created child Working Dilution plate | 2010-07-12 | jack       | Monday 12 July, 2010 |

    #Given I am on the events page for asset with barcode "1220001454858"
    Given I am on the events page for asset with barcode "SQPD-1454"
    Then the events table should be:
      | Message                         | Content    | Created by | Created at           |
      | Created child Stock Plate plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    #Given I am on the events page for asset with barcode "4361234567667"
    Given I am on the events page for asset with barcode "SQPD-1234567-2"
    Then the events table should be:
      | Message                          | Content    | Created by | Created at           |
      | Created Pico Dilution plate      | 2010-07-12 | jack       | Monday 12 July, 2010 |
      | Created child Pico Assay A plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
      | Created child Pico Assay B plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    #Given I am on the events page for asset with barcode "6251234567836"
    Given I am on the events page for asset with barcode "SQPD-1234567-1"
    Then the events table should be:
      | Message                           | Content    | Created by | Created at           |
      | Created Working Dilution plate    | 2010-07-12 | jack       | Monday 12 July, 2010 |
      | Created child Pico Dilution plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
      | Created child Gel Dilution plate  | 2010-07-12 | jack       | Monday 12 July, 2010 |
    #Given I am on the events page for asset with barcode "4331234567653"
    Given I am on the events page for asset with barcode "SQPD-1234567-3"
    Then the events table should be:
      | Message                    | Content    | Created by | Created at           |
      | Created Pico Assay A plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    #Given I am on the events page for asset with barcode "4341234567737"
    Given I am on the events page for asset with barcode "SQPD-1234567-4"
    Then the events table should be:
       | Message                    | Content    | Created by | Created at           |
       | Created Pico Assay B plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    #Given I am on the events page for asset with barcode "1931234567771"
    Given I am on the events page for asset with barcode "SQPD-1234567-5"
    Then the events table should be:
      | Message                    | Content    | Created by | Created at           |
      | Created Gel Dilution plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    #Given I am on the events page for asset with barcode "1220077777868"
    Given I am on the events page for asset with barcode "SQPD-1454-1"
    Then the events table should be:
      | Message                   | Content    | Created by | Created at           |
      | Created Stock Plate plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
