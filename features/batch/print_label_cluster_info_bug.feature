@batch
Feature: Change the side links in a batch depending on the pipeline

  Background:
    Given I am logged in as "user"
    And I have lab manager role

  Scenario Outline: Menu displayed
    Given I have a batch in "<pipeline>"
      And I am on the last batch show page
    Then I should see "Edit"
      And I <stock labels> "Print stock labels"
      And I <stock tubes> "Create stock tubes"

    Examples:
      | pipeline                          | stock labels   | stock tubes    |
      | Cherrypick                        | should not see | should not see |
