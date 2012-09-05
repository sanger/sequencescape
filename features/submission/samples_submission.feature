@submission @accession @sample_manifest @wip
Feature: Samples submission
  In order to request genotyping on samples
  As a study manager
  I need to submit requests
  So that Lab Technicians know exactly what i want
  And me being able to track progress of work

  Background:
    Given I am an "Manager" user logged in as "abc123"
    And I have an active study called "study B"
    And user "abc123" is a "manager" of study "study B"
    And I have an "approved" project called "project B"
    And the project "project B" has quotas and quotas are enforced

    Given I am visiting study "study B" homepage
    Then I should see "study B"
    When I follow "Register samples"
    Then I should see "Sample registration"
    When I follow "2. Spreadsheet load"
    Then I should see "Sample Registration using spreadsheet"
    When I attach the relative file "test/data/sample_info_valid.xls" to "file"
    When I press "Upload spreadsheet"
    When I press "Register samples"
    Then I should see "Your samples have been registered"

    Given I am visiting study "study B" homepage

  Scenario: Missed an accession number EBI. Gave us an error.
    When I follow "Create Submission"
    Then I should see "Please select a submission template"
    When I press "Next"
    Then I should see "Select a group to submit"
    And I should see "Double check and create your submission"

  Scenario: We provide to give them an accesion number EBI
    Given study "study B" has an accession number
    When I follow "Create Submission"
    Then I should see "Please select a submission template"
    When I press "Next"
    Then I should see "Select a group to submit"
    And I should see "Double check and create your order"
    When I select "asset_group_1" from "Select a group to submit"
    And I fill in "Fragment size required (from)" with "1"
    And I fill in "Fragment size required (to)" with "999"
    And I select "Custom" from "Library type"
    And I select "76" from "Read length"
    And I create the order and submit the submission
    Then I should see "Submission successfully created"
