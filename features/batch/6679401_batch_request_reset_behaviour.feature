Feature: Resetting batches and their requests across the various pipelines
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario Outline:

    And I have a batch with 5 requests for the "<pipeline>" pipeline
    And the batch and all its requests are pending

    Given I am on the "<pipeline>" pipeline page
    When I follow "View pending batch 1"
    Then I should not see "Fail batch or requests"
    When I follow "<link>"
    And I follow "Fail batch"
    And I check "Remove request" for 1 to 5
    And I select "Other" from "Select failure reason"
    And I press "Fail selected requests"
    Then I should see "removed."

    Then the 5 requests should be in the "<pipeline>" pipeline inbox

    Scenarios: Genotyping pipelines
      | pipeline               | workflow              | link                  |
      | Cherrypick             | Microarray genotyping | Select Plate Template |
