@batch
Feature: If a batch is released, the section Action/Task shouldn't be shown unless it is on a white list

  Background:
    Given I am logged in as "user"

  Scenario Outline: The show or hide the released Actions section for pipelines
  Given I have a "<batch_state>" batch in "<pipeline>"
    And I am on the last batch show page
  Then I should see "This batch belongs to pipeline: <pipeline>"
    And I should see "Events"
    And I <should_or_should_not> see "Actions"
  Examples:
    | pipeline                               | batch_state | should_or_should_not |
    | Cluster formation PE                   | released    | should not           |
    | Illumina-C Library preparation         | released    | should not           |
    | Cluster formation PE                   | pending     | should               |
    | Illumina-C Library preparation         | pending     | should               |
    | Cherrypick                             | released    | should               |
    | PacBio Library Prep                    | released    | should               |
    | PacBio Sequencing                      | released    | should               |
