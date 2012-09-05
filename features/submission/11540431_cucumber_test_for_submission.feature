@submission @javascript @autocomplete @wip @old_submission_ui
Feature: Added a new js version. Check that submission continues to work and Project is filled properly

  Background:
    Given I am an "Manager" user logged in as "abc123"
    And I have an active study called "Study B"
    And user "abc123" is a "manager" of study "Study B"
    And I have an "approved" project called "Project B"
    And the project "Project B" has quotas and quotas are enforced

    Given I am visiting study "Study B" homepage
    Then I should see "Study B"
    And the study "Study B" has an asset group of 10 samples called "asset_group_1"
    Given I have a project called "Project_Example_1"
    Given I have a project called "Project_Example_2"
    Given I have a project called "Pratical_1"
    Given I have a project called "Pre-Project"
    Given I have a project called "Test 1"
    Given I have a project called "Test 2"
    Given I have a project called "Surf_1"
    Given I have a project called "Woolfinite"
    Given I am visiting study "Study B" homepage


  Scenario: We provide to give them an accesion number EBI
    Given study "Study B" has an accession number
    When I follow "Create Submission"
    Then I should see "Please select a submission template"
    When I select "Library creation - Single ended sequencing" from "Template"
    When I press "Next"
    Then I should see "Select a group to submit"
    When I fill in "Project Name" with "Pr"
    Then I should see the following autocomplete options:
      | Pratical_1        |
      | Pre-Project       |
      | Project B         |
      | Project_Example_1 |
      | Project_Example_2 |
    When I fill in "Project Name" with "Project B"
    And I should see "Double check and create your order"
    When I select "asset_group_1" from "Select a group to submit"
    And I fill in "Fragment size required (from)" with "1"
    And I fill in "Fragment size required (to)" with "999"
    And I select "Custom" from "Library type"
    And I select "76" from "Read length"
    And I create the order and submit the submission
    Then I should see "Submission successfully built"
