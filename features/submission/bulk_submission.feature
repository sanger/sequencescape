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
    # And the study "abc123_study" has an asset group called "assetgroup123"
    And the study "abc123_study" has an asset group of 10 samples in "well" called "assetgroup123"
    # And I have a sample tube called "testing123" registered under study
    And study "abc123_study" has assets registered
   # And the sample tube "testing123" is in the asset group "assetgroup123"
    When I go to the create bulk submissions page
    Then I should see "Create a bulk submission"

  @this
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


  Scenario: Uploading a valid file with 1 submission but a deprecated template
    # When I upload a file with valid data for 1 submissions but deprecated template
    When I upload a file with deprecated data for 1 submissions
    Then I should see "Template: 'Cherrypick for pulldown - Pulldown WGS - HiSeq Paired end sequencing' is deprecated and no longer in use."


  Scenario: Uploading a valid file with 1 submission
    When I upload a file with valid data for 1 submissions
    Then I should see "Bulk submission successfully made"
    And I should see "Your submissions:"


  Scenario: Uploading a valid file with bait library specified should set the bait library name
    # Given I have a well called "testing123"
    # And the sample in the last well is registered under the study "abc123_study"
    When I upload a file with 2 valid SC submissions
    Then I should see "Your submissions:"
     And there should be an order with the bait library name set to "Bait library 1"
     And there should be an order with the bait library name set to "Bait library 2"
     And the last submission should have a priority of 1

  Scenario: Uploading a valid file with gb expected specified should set the gb expected
    # Given I have a well called "testing123"
    # And the sample in the last well is registered under the study "abc123_study"
    When I upload a file with valid data for 2 submissions
    Then I should see "Your submissions:"
     And there should be an order with the gigabases expected set to "1.35"


  @this
  Scenario: Uploading a valid file with 2 submissions
    When I upload a file with valid data for 2 submissions
    Then I should see "Bulk submission successfully made"
    And I should see "Your submissions:"

  Scenario: Uploading an invalid file with 1 submissions
    When I upload a file with invalid data for 1 submissions
    Then I should see "No user specified for testing124"
    Then there should be no submissions

  Scenario: Uploading an invalid file with 2 submissions
    When I upload a file with invalid data for 2 submissions
    Then I should see "There was a problem on row(s)"
    Then there should be no submissions

  Scenario: Uploading a file with conflicting orders
    When I upload a file with conflicting submissions
    Then I should see "Column, read length, should be identical for all requests in asset group assetgroup123"
    Then there should be no submissions

  Scenario: Uploading an invalid file with 2 submissions
    When I upload a file with 1 invalid submission and 1 valid submission
    Then I should see "There was a problem on row(s)"
    Then there should be no submissions

  Scenario: Uploading an empty file
    When I upload an empty file
    Then I should see "The supplied file was empty"

  Scenario: Uploading a file without a (valid) header row
    When I upload a file with an invalid header row
    Then I should see "The supplied file does not contain a valid header row"
    Then there should be no submissions

  Scenario: Leaving the file field blank
    When I submit an empty form
    Then I should see "can't be blank"

