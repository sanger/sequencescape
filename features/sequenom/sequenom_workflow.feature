@wip @depricated
Feature: The "Sequenom" project need to interact with plates for their 4-step workflow
  Background:
    Given I am logged in as "john_smith"

    Given there is at least one administrator
    And I have an active study called "Sequenom study"
    And user "john_smith" is an "owner" of study "Sequenom study"

    Given the study "Sequenom study" has a plate with barcode "DN99999F"

  Scenario: The scanned barcode does not match a valid plate barcode format
    Given I am on the Sequenom homepage
    When I fill in "Plate barcode" with the human barcode "FO99999S"
    And I press "Search"
    Then I should be on the Sequenom homepage
    And I should see "The barcode 1770099999675 () does not appear to be a valid plate barcode"

  Scenario: The scanned barcode does not match a plate
    Given I am on the Sequenom homepage
    When I fill in "Plate barcode" with the human barcode "DN12345U"
    And I press "Search"
    Then I should be on the Sequenom plate page for "DN12345U"

  Scenario: The scanned barcode matches a plate that has no events
    Given I am on the Sequenom homepage
    When I fill in "Plate barcode" with the human barcode "DN99999F"
    And I press "Search"
    Then I should be on the Sequenom plate page for "DN99999F"

  Scenario: The scanned barcode matches a plate with events
    Given the plate with barcode "DN99999F" has events:
      | message                       |
      | Something happened first      |
      | Then this happened            |
      | And finally this one occurred |
    When I am on the Sequenom plate page for "DN99999F"
    Then I should see "Something happened first"
    And I should see "Then this happened"
    And I should see "And finally this one occurred"
    And I should see a dropdown labeled "Process:" with:
      | PCR Mix    |
      | SAP Mix    |
      | IPLEX Mix  |
      | HPLC Water |
    And I should see a button marked "Add process"
    And I should see a field marked "Scan User ID barcode:"

  Scenario Outline: Marking a Sequenom step completed
    Given I am on the Sequenom plate page for "DN99999F"
    And a user with human barcode "ID99999D" exists
    When I select "<step>" from "Process:"
    And I fill in "Scan User ID barcode:" with the human barcode "ID99999D"
    And I press "Add process"
    Then I should be on the Sequenom plate page for "DN99999F"
    And I should see "<step> step completed"
    And I should see "<step> step for plate 1220099999705 (DN99999F) marked as completed"

    Examples:
      | step       |
      | PCR Mix    |
      | SAP Mix    |
      | IPLEX Mix  |
      | HPLC Water |
