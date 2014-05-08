@sample @registration
Feature: Sample registration from a spreadsheet containing many samples
  In order to request genotyping on samples
  As a collaborator
  I want to be able to upload a large list of samples
  So that Lab Technicians know what to expect to work with
  And be able to track progress of work
  And keep cost under control
  And to handle asset groups for 12 lanes

  Background:
    Given there are no samples

    Given I am an "External" user logged in as "abc123"
    And I have an active study called "study A"
    And user "abc123" is a "manager" of study "study A"
    And the study have a workflow

    Given I am visiting study "study A" homepage
    Then I should see "study A"
    When I follow "Register samples"
    Then I should see "Sample registration"

  Scenario: Insert samples over the upload limit with new AssetGroupName
    When I follow "2. Spreadsheet load"
    And I attach the relative file "test/data/just_too_big_sample_info.xls" to "file"
    When I press "Upload spreadsheet"
    Then I should see "You can only load 380 samples at a time. Please split the file into smaller groups of samples."
    And I should not see "Processing your file: please wait a few minutes..."
    And a "0" number of "sample" should be created

  Scenario: Insert 12 samples under the upload limit with new AssetGroupName
    When I follow "2. Spreadsheet load"
    And I attach the relative file "test/data/two_plate_sample_info_valid.xls" to "file"
    When I press "Upload spreadsheet"
    Then I should see "Sample registration"
    And I should not see "Processing your file: please wait a few minutes..."
    And I should see "Your file has been processed"

    When I press "Register samples"
    Then I should see "Samples"
    And a "12" number of "sample" should be created

    When I follow "Samples"
    Then I should see "sample01_01"
    And I should see "sample01_26"

    When I follow "Back to study"
    Then I should see "Asset groups"

    When I follow "Asset groups"
    Then I should see "asset_group_1"

    When I follow "asset_group_1"
    Then I should see "sample01_01"

  Scenario: Attempt to upload samples from a spreadsheet from an old or invalid format
    When I follow "2. Spreadsheet load"
    And I attach the relative file "test/data/four_plate_sample_info_invalid.xls" to "file"
    When I press "Upload spreadsheet"
    Then I should see "Please check that your spreadsheet is in the latest format"
    And I should not see "Processing your file: please wait a few minutes..."
    And a "0" number of "sample" should be created

