@batch @pipeline
Feature: Show the date of creation of a batch

  Background:
    Given I am logged in as "user"

  Scenario Outline: The batch is pending and the section Action is showed
    Given I have a batch in "<pipeline>"
      And I am on the last batch show page
    Then I should see "Created at"
      And I should see "Pipeline <pipeline>"

    Examples:
      | pipeline             |
      | Cherrypick           |
      | MiSeq sequencing     |
