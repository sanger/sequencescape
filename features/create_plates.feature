@timetravel @barcode-service @printing @slf
Feature: Printing new plate barcodes
  Background:
    Given I am logged in as "user"
    And the plate barcode webservice returns "1234569"
    And the "96 Well Plate" barcode printer "xyz" exists
    And I freeze time at "Mon Jul 12 10:23:58 UTC 2010"
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
    Then I should see "Failed to create plates"

  Scenario: Creating plates where the scanner appends a carriage return
    Given I am on the new plate page
    When I fill in "User barcode" with multiline text
    """
    2470000100730

    """
    When I select "Stock Plate" from "Plate purpose"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"
    And I should be on the new plate page

  Scenario Outline: Creating plates
    Given I am on the new plate page
    And the plate barcode webservice returns "1234570"
    When I select "<plate_purpose>" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"
    And I should be on the new plate page

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
    And the plate barcode webservice returns "1234570"
    And a plate with purpose "Cherrypicked" and barcode "1220001454858" exists
    And I am on the new plate page
    Then I should see "Create Plates"

    When I select "<plate_purpose>" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"
    And I should be on the new plate page

    When I select "<plate_purpose>" from "Plate purpose"
    And I fill in the field labeled "Source plates" with "1220001454858"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And I press "Submit"
    Then I should see "Scanned plate 1220001454858 has a purpose Cherrypicked not valid"
    And I should be on the new plate page

    Examples:
      | plate_purpose         | parent_plate_purpose |
      | Working dilution      | Stock Plate          |
      | Pico dilution         | Working dilution     |
      | Pico Assay Plates     | Pico dilution        |

  @xml @qc_event
  Scenario: Create all QC plates for SLF
    Given a plate with purpose "Stock plate" and barcode "1221234567841" exists
    And a plate of type "Plate" with barcode "1220001454858" exists
    Given I am on the new plate page
    Then I should see "Create Plates"

    When I select "Pico Standard" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"

    And the plate barcode webservice returns "77777"
    When I fill in the field labeled "Source plates" with "1220001454858"
    When I select "Stock Plate" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"

    And the plate barcode webservice returns "77777"
    When I fill in the field labeled "Source plates" with "1221234567841"
    When I select "Working dilution" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"

    And the plate barcode webservice returns "77777"
    When I fill in the field labeled "Source plates" with "6251234567836"
    When I select "Pico dilution" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"

    And the plate barcode webservice returns "77777"
    When I fill in the field labeled "Source plates" with "4361234567667"
    When I select "Pico Assay Plates" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"

    And the plate barcode webservice returns "77777"
    When I fill in the field labeled "Source plates" with "6251234567836"
    When I select "Gel Dilution Plates" from "Plate purpose"
    And I fill in "User barcode" with "2470000100730"
    And I select "xyz" from "Barcode printer"
    And Pmb has the required label templates
    And Pmb is up and running
    And I press "Submit"
    Then I should see "Created plates and printed barcodes"
    And plate with barcode "4331234567653" should exist
    And plate with barcode "4341234567737" should exist
    And plate with barcode "1931234567771" should exist
    And plate with barcode "1220077777868" should exist

    Given I am on the events page for asset with barcode "1221234567841"

    Then the events table should be:
      | Message                              | Content    | Created by | Created at           |
      | Created child Working Dilution plate | 2010-07-12 | jack       | Monday 12 July, 2010 |

    Given I am on the events page for asset with barcode "1220001454858"
    Then the events table should be:
      | Message                         | Content    | Created by | Created at           |
      | Created child Stock Plate plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    Given I am on the events page for asset with barcode "4361234567667"
    Then the events table should be:
      | Message                          | Content    | Created by | Created at           |
      | Created Pico Dilution plate      | 2010-07-12 | jack       | Monday 12 July, 2010 |
      | Created child Pico Assay A plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
      | Created child Pico Assay B plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    Given I am on the events page for asset with barcode "6251234567836"
    Then the events table should be:
      | Message                           | Content    | Created by | Created at           |
      | Created Working Dilution plate    | 2010-07-12 | jack       | Monday 12 July, 2010 |
      | Created child Pico Dilution plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
      | Created child Gel Dilution plate  | 2010-07-12 | jack       | Monday 12 July, 2010 |
    Given I am on the events page for asset with barcode "4331234567653"
    Then the events table should be:
      | Message                    | Content    | Created by | Created at           |
      | Created Pico Assay A plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    Given I am on the events page for asset with barcode "4341234567737"
    Then the events table should be:
       | Message                    | Content    | Created by | Created at           |
       | Created Pico Assay B plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    Given I am on the events page for asset with barcode "1931234567771"
    Then the events table should be:
      | Message                    | Content    | Created by | Created at           |
      | Created Gel Dilution plate | 2010-07-12 | jack       | Monday 12 July, 2010 |
    Given I am on the events page for asset with barcode "1220077777868"
    Then the events table should be:
      | Message                   | Content    | Created by | Created at           |
      | Created Stock Plate plate | 2010-07-12 | jack       | Monday 12 July, 2010 |

    Given I am on the pico dilution index page
    Then the XML response should be:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <records type="array">
        <record>
          <study_name/>
          <pico-dilution>
            <created-at type="datetime">2010-07-12T11:23:58+01:00</created-at>
             <dilution_factor>1.0</dilution_factor>
            <barcode>4361234567667</barcode>
            <child-barcodes type="array">
              <child-barcode>
                <created-at type="datetime">2010-07-12T11:23:58+01:00</created-at>
                <dilution_factor>1.0</dilution_factor>
                <barcode>4331234567653</barcode>
              </child-barcode>
              <child-barcode>
                <created-at type="datetime">2010-07-12T11:23:58+01:00</created-at>
                <dilution_factor>1.0</dilution_factor>
                <barcode>4341234567737</barcode>
              </child-barcode>
            </child-barcodes>
          </pico-dilution>
        </record>
      </records>
      """
