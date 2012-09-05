@javascript @submission @wip @old_submission
Feature: Submission creation
  So that biological work can be requested
  And tracked by users, managers and administrative staff
  Users with privilege
  need to have enough quotas for the work they want
  And need to create a request of work

  Background:
    Given I am logged in as "user"
    And I am using "local" to authenticate
    And I have administrative role
    And I have an "active" study called "abc123_study"

    # Need more than 8 projects to trigger the autocompletion field view
    Given I have 10 "approved" projects based on "abc123_project" with enough quotas

    Given study "abc123_study" has asset and assetgroup
    When I go to the study workflow page for "abc123_study"
    Then I should see "abc123_study"
    When I follow "Create Submission"
    Then I should see "Please select a submission template"
    When I select "Pulldown library creation - Single ended sequencing" from "Template"
    When I press "Next"

  Scenario: No project provided
    Then I should see "Select a group to submit"
    When I select "new_asset_group" from "asset_group"
    And I press "Create Order"
    Then I should see "Project can't be blank"

  Scenario: No asset group provided
    When I press "Create Order"
    Then I should see "No assets found"
