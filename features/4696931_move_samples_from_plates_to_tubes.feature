Feature: Creating sample tubes from a plate, add to asset group, and print barcodes
  Background:
    Given I am logged in as "user"
    And the "96 Well Plate" barcode printer "xyz" exists
    And freezer location "Another lab freezer" exists
    Given a study named "Study 4696931" exists
    Given I visit a page with url "/plates/to_sample_tubes"
    Then I should see "Convert plates to tubes"
    And I should see "Source plates"
    And I should see "Study"
    And I should see "Destination freezer"
    And I should see "Barcode printer"

  Scenario: plate barcode scanned and plate exists
    Given a plate of type "Plate" with barcode "1220128459804" exists
    And plate with barcode "128459" has a well
    When I fill in the field labeled "Source plates" with "1220128459804"
    And I select "Study 4696931" from "Study"
    And I select "Another lab freezer" from "Destination freezer"
    And I select "xyz" from "Barcode printer"
    When I press "Submit"
    Then I should see "Created tubes and printed barcodes"
    Then I should see "Please select a submission template"
    When I press "Next"
    Then I should see "Study 4696931 : REQUEST Next-gen sequencing"
    And I should see "128459"

  Scenario: plate ID typed in
    Given a plate of type "Plate" with barcode "1220128459804" exists
    And plate with barcode "128459" has a well
    When I fill in the field labeled "Source plates" with "128459"
    And I select "Study 4696931" from "Study"
    And I select "Another lab freezer" from "Destination freezer"
    And I select "xyz" from "Barcode printer"
    When I press "Submit"
    Then I should see "Created tubes and printed barcodes"
    Then I should see "Please select a submission template"
    When I press "Next"
    Then I should see "Study 4696931 : REQUEST Next-gen sequencing"
    And I should see "128459"

  Scenario: plate barcode scanned and plate exists but has no wells
    Given a plate of type "Plate" with barcode "1220128459804" exists
    When I fill in the field labeled "Source plates" with "1220128459804"
    And I select "Study 4696931" from "Study"
    And I select "Another lab freezer" from "Destination freezer"
    And I select "xyz" from "Barcode printer"
    When I press "Submit"
    Then I should see "Failed to create sample tubes"
    And I should see "Convert plates to tubes"

  Scenario: plate barcode scanned and plate does not exist
    When I fill in the field labeled "Source plates" with "1220128459804"
    And I select "Study 4696931" from "Study"
    And I select "Another lab freezer" from "Destination freezer"
    And I select "xyz" from "Barcode printer"
    When I press "Submit"
    Then I should see "Failed to create sample tubes"
    And I should see "Convert plates to tubes"

  Scenario: no plates scanned
    When I select "Another lab freezer" from "Destination freezer"
    And I select "Study 4696931" from "Study"
    And I select "xyz" from "Barcode printer"
    When I press "Submit"
    Then I should see "Failed to create sample tubes"
    And I should see "Convert plates to tubes"
