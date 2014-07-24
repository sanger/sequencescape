@javascript @study @release_agreement
Feature: Studies have a release agreement
  Background:
    Given I am an "administrator" user logged in as "John Smith"
    Given a faculty sponsor called "Jack Sponsor" exists
    Given I am on the study creation page
    And I fill in "Study name" with "Testing release agreements"
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I fill in "Study description" with "Checking that release agreements behave properly"
    And I select "No" from "Do any of the samples in this study contain human DNA?"
    And I select "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I select "managed" from "What is the data release strategy for this study?"

  Scenario: Using the standard WTSI agreement
    Given I select "Yes" from "Will you be using WTSI's standard access agreement?"
    When I press "Create"
    Then I should be on the study workflow page for "Testing release agreements"
    And I should see "Your study has been created"

  Scenario: Using a non-standard agreement but no file uploaded
    Given I select "No" from "Will you be using WTSI's standard access agreement?"
    When I press "Create"
    Then I should be on the studies page
    And I should see "Data release non standard agreement can't be blank"

  Scenario: Using a non-standard agreement with a file uploaded
    Given I select "No" from "Will you be using WTSI's standard access agreement?"
    And I attach the relative file "test/data/blah.fasta" to "Please upload the access agreement that you will be using"
    When I press "Create"
    Then I should be on the study workflow page for "Testing release agreements"
    And I should see "Your study has been created"

