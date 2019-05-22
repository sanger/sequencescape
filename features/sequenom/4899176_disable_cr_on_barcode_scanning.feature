@javascript @sequenom @barcode-service @sequenom_creation
Feature: Disable form submission on carriage return on Sequenom plate creation page
  I have barcode scanners which send a carriage return after the barcode.This is to separate
  out barcodes when scanned into a text area. To make it work with text input fields, the carriage return
  needs to be trapped or the form will submit. So make the carriage return change the focus to the next
  input box to make it work in a high throughput manner

  Background:
    Given I am logged in as "user"
    And today's date is "4 Aug 2010"
    And the plate barcode webservice returns "1234567"
    And the "96 Well Plate" barcode printer "xyz" exists
    And user "jack" exists with barcode "ID100I"

  Scenario: Creating a Sequenome plate from Stock Dilution Plates.
    Given I am setup for sequenome QC
      And I am on the new Sequenom QC Plate page
    When I fill in "User barcode" with multiline text
"""
2470000100730

"""
    Then I should not see "successfully created"
    When I fill in "Plate 1" with multiline text
"""
1220125054743

"""
    Then I should not see "successfully created"
    When I fill in "Plate 2" with multiline text
"""
1220125056761

"""
    Then I should not see "successfully created"
    When I fill in "Plate 3" with multiline text
"""
1220125069815

"""
    Then I should not see "successfully created"
    When I fill in "Plate 4" with multiline text
"""
1220125048766

"""
    Then I should not see "successfully created"
    And I fill in "Number of Plates" with "1"
    And select "QC" from "Plate Type"
    And select "xyz" from "Barcode Printer"
    And Pmb has the required label templates
    And Pmb is up and running
    When I press "Create new Plate"
    And I should see "Sequenom QC Plate QC125054_125056_125069_125048_20100804 successfully created"
    And I should see "labels printed"
    # And exactly 1 barcodes different should have been sent to print
    And I should be on the new Sequenom QC Plate page
