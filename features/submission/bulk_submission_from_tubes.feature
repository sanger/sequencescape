@submission @bulk_submissions
Feature: Bulk Submission
  So that biological work can be requested
  in a large batch rather than separate
  submissions which take a long time to do,
  Users with privileges should be able to submit a
  csv spreadsheet with multiple submissions

  Background:
    Given I am logged in as "user"
    And I am using "local" to authenticate
    And I have a Tube submission template
    And I have administrative role
    And I have an "active" study called "abc123_study"
    And I have a project called "Test project"
    # And the study "abc123_study" has an asset group called "assetgroup123"
    And the study "abc123_study" has an asset group of 5 samples in SampleTubes called "assetgroup123"
    And sample tubes are barcoded sequentially from 1
    When I go to the create bulk submissions page
    Then I should see "Bulk Submission New"

  Scenario: Uploading a valid file with 1 submission
    When I upload a file with valid data for 1 tube submissions
    And I should see "Your bulk submission has been processed."
    And the last submission should contain two assets
    And the last submission should contain the tube with barcode "NT1O"
    And the last submission should contain the tube with barcode "NT2P"

  Scenario: With clashing asset groups
    And the study "abc123_study" has an asset group of 2 samples in SampleTubes called "novel_asset_group"
    When I upload a file with valid data for 1 tube submissions
    Then I should not see "Your bulk submission has been processed"
    And I should see "Asset Group 'novel_asset_group' contains different assets to those you specified. You may be reusing an asset group name"
