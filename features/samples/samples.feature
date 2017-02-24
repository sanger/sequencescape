@sample
Feature: Show/update samples
  Background:
    Given I am a "Internal" user logged in as "John Smith"

  Scenario: View the manifest that a sample was created from
    Given I have a sample called "sample_test" with metadata
     And sample "sample_test" came from a sample manifest
     And I am on the show page for sample "sample_test"
    Then I should see "Manifest_1"
    When I follow "Manifest_1"
    Then I should see "Download Blank Manifest"

  Scenario: A sample doesnt have a sample manifest
    Given I have a sample called "sample_test" with metadata
     And I am on the show page for sample "sample_test"
    Then I should not see "Manifest_1"

  Scenario: All sample metadata should show in next-release workflow
    Given I have a sample called "sample_test" with metadata
     And user "John Smith" has a workflow "Next-gen sequencing"
     And I am on the show page for sample "sample_test"
    Then I should see "Cohort"
     And I should see "Gender"
     And I should see "Country of origin"
    Then I should see "Sequencescape Sample ID"
     And I should see "Public Name"
     And I should see "TAXON ID"

  Scenario: All sample metadata should show in genotyping workflow
    Given I have a sample called "sample_test" with metadata
     And user "John Smith" has a workflow "Microarray genotyping"
     And I am on the show page for sample "sample_test"
    Then I should see "Cohort"
     And I should see "Gender"
     And I should see "Country of origin"
    Then I should see "Sequencescape Sample ID"
     And I should see "Public Name"
     And I should see "TAXON ID"

  Scenario: User is an administrator
    Given user "John Smith" has a workflow "Microarray genotyping"
     And the sample named "sample_3958121" exists
     And I am an administrator
     And I am on the show page for sample "sample_3958121"
    When I follow "Edit"
    Then I should be on the edit page for sample "sample_3958121"

  Scenario: User is not the owner nor an administrator
    Given user "John Smith" has a workflow "Microarray genotyping"
     And the sample named "sample_3958121" exists
     And I am on the edit page for sample "sample_3958121"
    Then I should be on the show page for sample "sample_3958121"
     And I should see "Sample details can only be altered by the owner or an administrator or manager"
     