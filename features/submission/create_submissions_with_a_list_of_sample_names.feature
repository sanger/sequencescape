# rake features FEATURE=features/plain/submissions/using_templates.feature
@submission @submission_template  @wip @old_submission
Feature: Creating submissions through the submission templates
  Background:
    Given I am an "administrator" user logged in as "John Smith"

    Given I have a project called "Project testing submission templates"
    And project "Project testing submission templates" has enforced quotas
    And I have an active study called "Study testing submission templates"

    Given all of this is happening at exactly "13-September-2010 09:30"

  Scenario: Creating a valid submission for microarray genotyping using sample name
    Given the study "Study testing submission templates" has an asset group of 10 samples in "well" called "Asset group for submission templates"
    And all of the wells are on a "Stock plate" plate

    Given the project "Project testing submission templates" has a "Cherrypick" quota of 999
    And the project "Project testing submission templates" has a "DNA QC" quota of 999
    And the project "Project testing submission templates" has a "Genotyping" quota of 999

    Given I am on the "Microarray genotyping" submission template selection page for study "Study testing submission templates"
    When I select "Microarray genotyping" from "Template"
    And I press "Next"

    # Microarray genotyping has no extra information attached to its request types
    Then I should not see "The following parameters will be applied to all the samples in the group"
    Then I should see "Enter a list of sample name"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I fill in "sample_names" with "asset_group_for_submission_templates_sample_1"
    When I create the order and submit the submission

    Then I should see "Submission successfully built"
    And I should see "Your submission is currently pending"
    And I should see "Submission created at: Monday 13 September, 2010 09:30"
    And I should see the submission request types of:
      |Cherrypick|
      |DNA QC    |
      |Genotyping|

  Scenario: Creating a submission with wrong sample names should fail
    Given the study "Study testing submission templates" has an asset group of 10 samples in "well" called "Asset group for submission templates"
    And all of the wells are on a "Stock plate" plate

    Given the project "Project testing submission templates" has a "Cherrypick" quota of 999
    And the project "Project testing submission templates" has a "DNA QC" quota of 999
    And the project "Project testing submission templates" has a "Genotyping" quota of 999

    Given I am on the "Microarray genotyping" submission template selection page for study "Study testing submission templates"
    When I select "Microarray genotyping" from "Template"
    And I press "Next"

    # Microarray genotyping has no extra information attached to its request types
    Then I should not see "The following parameters will be applied to all the samples in the group"
    Then I should see "Enter a list of sample name"

    When I select "Study testing submission templates" from "Select a study"
    When I select "Project testing submission templates" from "Select a financial project"
    And I fill in "sample_names" with "foo"

    But I press "Create Order"

    Then I should not see "Order successfully created"
    Then I should see "samples foo not found"
