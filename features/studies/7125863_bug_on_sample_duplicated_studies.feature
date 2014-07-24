@sample @allow-rescue
Feature: Samples should have only one link to study.
  Background:
    Given I am an "administrator" user logged in as "John Doe"
    Given the sample named "Sample_PT_7125863" exists
    Given I have a study called "Study_PT_7125863"
    Given the sample named "Sample_PT_7125863" belongs to the study named "Study_PT_7125863"

  Scenario: Insert a second same study from interface
    Given I am on the show page for sample "Sample_PT_7125863"
    Then I should see "Study_PT_7125863"
    When I select "Study_PT_7125863" from "Add to study"
    And I press "Add"
    Then I should see "Sample cannot be added to the same study more than once"
    And I should see one link with text "Study_PT_7125863"
    And the sample "Sample_PT_7125863" should belong to the study named "Study_PT_7125863" only once

  Scenario: Insert a second same study using import SNP
    When I try to set the sample named "Sample_PT_7125863" as belonging to the study named "Study_PT_7125863"
