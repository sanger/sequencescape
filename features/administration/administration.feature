@admin
Feature: Administration
  In order to allow certain users to administer the system
  admin users
  wants an administrative area with access controls

  @wip
  Scenario: Admin user logs into the system
    Given I am using "local" to authenticate
    And I am logged in as "admin"
    And I have administrative role
    When I go to the homepage
    Then I should be logged in as "admin"
    And I should see "Admin"
    And I should not be on the login page
