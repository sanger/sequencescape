@batch @regression
Feature: Batch progression
  Background:
    Given I am logged in as "me"

    Scenario: Release batch
    Given I have a "completed" batch in "MiSeq sequencing"
    When I release the last completed batch
    Then I should see "Released" within "div#batch_events"
    Then I should see "me" within "div#batch_events"

  Scenario: Finish batch
    Given I have a "started" batch in "MiSeq sequencing"
    When I finish the last started batch
    When I on batch page
    Then I should see "Complete" within "div#batch_events"
    Then I should see "me" within "div#batch_events"
