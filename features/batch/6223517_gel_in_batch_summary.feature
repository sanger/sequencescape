@fragment @library_preparation @batch @javascript
Feature: Fragment archive in library preparation batch
  Background:
    Given I am logged in as "user"

  Scenario: Add a fragment to batch
    Given I have a batch with 1 request for the "Illumina-C Library preparation" pipeline
    Given I on batch page
    Then I should see "Gel"
    When I follow "Gel"
    Then I should see "Fragment"
    When I follow "Fragment"
    And I fill in "start for asset #1" with "start value"
    When I press "Next step"
    And I follow "View summary"
    Then I should see "Fragment"
    And I should see "start value"
