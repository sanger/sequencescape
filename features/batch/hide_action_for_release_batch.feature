@batch
Feature: If a batch is released, the section Action/Task shouldn't be shown unless it is on a white list

  Background:
    Given I am logged in as "user"

  Scenario Outline: The show or hide the released Actions section for pipelines
  Given I have a "<batch_state>" batch in "<pipeline>"
    And I am on the last batch show page
  Then I should see "This batch belongs to pipeline: <pipeline>"
    And I should see "EVENTS"
    And I <should_or_should_not> see "ACTIONS"
  Examples:
    | pipeline                               | batch_state | should_or_should_not |
    | Cluster formation PE                   | released    | should not           |
    | Illumina-B MX Library Preparation      | released    | should not           |
    | Illumina-C Library preparation         | released    | should not           |
    | Cluster formation PE                   | pending     | should               |
    | Illumina-B MX Library Preparation      | pending     | should               |
    | Illumina-C Library preparation         | pending     | should               |
    | Pulldown Multiplex Library Preparation | released    | should               |
    | Cherrypicking for Pulldown             | released    | should               |
    | Genotyping                             | released    | should               |
    | DNA QC                                 | released    | should               |
    | Cherrypick                             | released    | should               |
    | PacBio Sample Prep                     | released    | should               |
    | PacBio Sequencing                      | released    | should               |
