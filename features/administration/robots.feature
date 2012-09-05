@robots @slf
Feature: Manage robots for SLF

  Background:
    Given I am an "administrator" user logged in as "user"
    When I follow "Admin"
    Then I should see "Administration"
    When I follow "Robot management"

  Scenario: Add new robot
    When I follow "New robot"
    Then I should see "New robot"
    When I fill in "Name" with "A robot"
    And I fill in "Location" with "A lab"
    And I press "Create"
    Then I should see "Robot was successfully created"
    When I follow "Manage Properties"
    And I follow "New property"
    When I fill in the following:
         | Name  | SCR1  |
         | Value | 123   |
         | Key   | bed_1 |
    And I press "Create"
    Then I should see "SCR1"
    When I follow "Back to Robot"
    Then I should see "SCR1"
    And I should see "A robot"
    When I follow "All robots"
    Then I should see "A robot"

