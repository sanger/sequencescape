@barcode-service
Feature: Printing new plate barcodes in pulldown
  Background:
    Given I am logged in as "user"
    And the plate barcode webservice returns "1234567"
    And the "96 Well Plate" barcode printer "xyz" exists
    And I have an active study called "Test study"

  Scenario Outline: Creating child plates and verifying plates are linked
    Given I am on the pulldown homepage
    And a plate of type "<plate_type>" with barcode "<barcode>" exists
    And asset with barcode "<barcode>" belongs to study "Test study"
    When I follow "Create Plates"
    When I fill in the field labeled "Source plates" with "<barcode>"
    And I select "xyz" from "Barcode printer"
    When I press "Submit"
    Then plate "<barcode>" should have a child plate of type "<child_plate_type>"
    Then I should see "Created plates and printed barcodes"
    And I should see "Create new plates"
    When I follow "Pulldown Home"
    Then I should see barcode "<child_barcode>"
    When I follow "Verify Plates"
    When I fill in the field labeled "Source plate" with "<barcode>"
    When I fill in the field labeled "Target plate" with "<child_barcode>"
    When I press "Submit"
    Then I should see "Success: plates match"
    And I should see "Verify plates"

    Examples:
    | barcode        | child_barcode  | plate_type                   | child_plate_type             |
    | 1630133339754  | 1650133339660  | PulldownAliquotPlate         | PulldownSonicationPlate      |
    | 1650133339660  | 1670133339804  | PulldownSonicationPlate      | PulldownRunOfRobotPlate      |
    | 1670133339804  | 1690133339710  | PulldownRunOfRobotPlate      | PulldownEnrichmentOnePlate   |
    | 1690133339710  | 1710133339852  | PulldownEnrichmentOnePlate   | PulldownEnrichmentTwoPlate   |
    | 1710133339852  | 1730133339768  | PulldownEnrichmentTwoPlate   | PulldownEnrichmentThreePlate |
    | 1730133339768  | 1750133339674  | PulldownEnrichmentThreePlate | PulldownEnrichmentFourPlate  |
    | 1750133339674  | 1770133339818  | PulldownEnrichmentFourPlate  | PulldownSequenceCapturePlate |
    | 1770133339818  | 1790133339724  | PulldownSequenceCapturePlate | PulldownPcrPlate             |
    | 1790133339724  | 1810133339866  | PulldownPcrPlate             | PulldownQpcrPlate            |

  Scenario: Creating a child plate where the input is empty
    Given I am on the pulldown homepage
    Then I should see "Create Plates"
    When I follow "Create Plates"
    And I select "xyz" from "Barcode printer"
    When I press "Submit"
    Then I should see "Failed to create plates"
    And I should not see "Created plates and printed barcodes"
    And I should see "Create new plates"


