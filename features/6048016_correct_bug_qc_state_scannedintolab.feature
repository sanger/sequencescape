@reception
Feature: I want to scan an asset into a lab reception
  Background:
    Given I am an "External" user logged in as "abc123"
    Given a tube named "Test Tube" with barcode "1221234567841" exists

    Scenario: Scan a plate into SLF and change qc state in pending
      And I am on the show page for labware "Test Tube"
      And I should not see "QC state"
      When I follow "Reception"
      Then I should see "Scan your sample"
      And I fill in "barcode_0" with "1221234567841"
      And I press "Submit"
      Then I should see "I have placed the above barcoded labware in the appropriate reception fridge"
      And I should see "DN1234567"
      And I press "Confirm"
      Then I should see "Successfully updated"
      And I am on the show page for labware "Test Tube"
      And I should see "pending"
      When I follow "Event history"
      And I should see "Scanned into"

    Scenario Outline:: Scan a plate into SLF with qc state different, add an event and change qc state only if was nil
      Given for asset "Test Tube" a qc state "<qc_state>"
      And I am on the show page for labware "Test Tube"
      And I should see "QC state"
      And I should see "<qc_state>"
      When I follow "Reception"
      Then I should see "Scan your sample"
      And I fill in "barcode_0" with "1221234567841"
      And I press "Submit"
      Then I should see "I have placed the above barcoded labware in the appropriate reception fridge"
      And I should see "DN1234567"
      And I press "Confirm"
      Then I should see "Successfully updated"
      And I am on the show page for labware "Test Tube"
      And I should see "QC state"
      And I should see "<qc_state>"
      When I follow "Event history"
      And I should see "Scanned into"


      Examples:
      | qc_state    |
      | failed      |
      | passed      |
