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
    And I have administrative role
    And I have an "active" study called "abc123_study"
    And I have a project called "Test project"
    And the study "abc123_study" has an asset group of 10 samples in "well" called "assetgroup123"
    When I go to the create bulk submissions page
    Then I should see "Bulk Submission New"

  Scenario: Link samples to the corresponding study when using bulk_submission (User story ss448)
    When I have a study 'StudyA'
    And I have a study 'StudyB'
    And I have a sample 'SampleTest'
    And the sample 'Sampletest' belongs to study 'StudyA'

    And I have a plate 'AssetTest' that has a well in location 'A1' that contains the sample 'SampleTest'
    And the plate 'AssetTest' has a barcode '111111'

    Then the sample 'Sampletest' should belong to study 'StudyA'
    And the sample 'Sampletest' should not belong to study 'StudyB'

    When I upload a file with a plate 'AssetTest' with a well in location 'A1' that contains the sample 'SampleTest' for study 'StudyB'

    Then I should see "Bulk submission successfully made"

    Then the sample 'Sampletest' should belong to study 'StudyA'
    And the sample 'Sampletest' should belong to study 'StudyB'


  Scenario: Uploading a valid file with bait library specified should set the bait library name
    When I upload a file with 2 valid SC submissions
    Then I should see "Your submissions:"
     And there should be an order with the bait library name set to "Bait library 1"
     And there should be an order with the bait library name set to "Bait library 2"
     And the last submission should have a priority of 1
