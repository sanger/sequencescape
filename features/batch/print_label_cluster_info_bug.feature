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
      | Cluster formation PE              | should not see | should not see |
      | Cluster formation SE              | should not see | should not see |
      | Illumina-C Library preparation    | should see     | should see     |
      | Cherrypick                        | should not see | should not see |
