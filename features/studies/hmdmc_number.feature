@study
Feature: HMDMC number should be visible in details
  Background:
    Given I am logged in as "user"
    And I have a study called "Test study"
    And I have a study called "Test study human" that requires ethical approval and has HMDMC approval number ""
    And I have a study called "Test study human 2" that requires ethical approval and has HMDMC approval number "12345"

  Scenario: HMDMC should be in details

    Given I am on the show page for study "Test study"
    When I follow "Study details"
    Then I should not see "HMDMC approval number: "

    Given I am on the show page for study "Test study human"
    When I follow "Study details"
    Then I should see "HMDMC approval number: Not specified"

    Given I am on the show page for study "Test study human 2"
    When I follow "Study details"
    Then I should see "HMDMC approval number: 12345"
