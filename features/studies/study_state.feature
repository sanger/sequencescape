Feature: You should be able to change study state

  Scenario: Freeze study
    Given I am an "administrator" user logged in as "John Smith"
    And I have an "active" study called "Test study"
    And I am on the information page for study "Test study"
    Then I should see "Deactivate Study"
    When I follow "Deactivate Study"
    And I fill in "Reason for deactivation" with "some reason"
    And I press "Deactivate"
    Then I should see "This study has been deactivated: some reason"
