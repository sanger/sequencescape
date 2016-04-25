@admin @plate_purpose
Feature: Manage Plate Purposes

  Background:
    Given I am a "administrator" user logged in as "user"
    And I am on the plate purpose homepage
    Then I should see "Listing All Plate Purposes"
    And I should see "Stock Plate"
    When I follow "New Plate Purpose"

  Scenario: Adding a new plate purpose
    And I fill in the field labeled "Name" with "A new plate purpose"
    And I press "Create"
    Then I should see "Plate Purpose was successfully created"
    And I should be on the plate purpose homepage
    And I should see "A new plate purpose"
    When I follow "Edit A new plate purpose"
    Then I should see "Editing Plate Purpose"
    Then I fill in the field labeled "Name" with "Renamed plate purpose"
    And I press "Update"
    Then I should see "Plate Purpose was successfully updated"
    And I should be on the plate purpose homepage
    And I should see "Renamed plate purpose"
    And I should not see "A new plate purpose"

  Scenario: Adding an invalid plate purpose name with a space at the end
    And I fill in the field labeled "Name" with "ABC   "
    And I press "Create"
    Then I should see "Name is invalid"

  Scenario: Adding an invalid plate purpose name with a space at the beginning
    And I fill in the field labeled "Name" with "   ABC"
    And I press "Create"
    Then I should see "Name is invalid"


