@admin @barcode-service
Feature: Manage barcode printers

  Background:
    Given I am a "administrator" user logged in as "user"
    And I am on the homepage

  Scenario: Add a printer and update it
    When I follow "Admin"
    Then I should see "Administration"
    When I follow "Printer management"
    Then I should see "Barcode Printers"
    When I follow "Create Barcode Printer"
    Then I should see "New Barcode Printer"
    When I fill in "Name" with "test_printer"
    When I select "96 Well Plate" from "Barcode printer type"
    And I press "Submit"
    Then I should see "Barcode Printer was successfully created."
    And I should see "Barcode Printers"
    And I should see "96 Well Plate"
    And I should see "test_printer"
    When I follow "Edit printer test_printer"
    Then I should see "Editing Barcode Printer"
    When I select "384 Well Plate" from "Barcode printer type"
    And I press "Submit"
    Then I should see "Barcode Printer was successfully updated."
    And I should see "test_printer"
    And I should see "384 Well Plate"
