@study @admin
Feature: Study administration
    Owners and administrators can update the approval
    status for a study

  Background:
    Given I have an active study called "Study B"

  Scenario: User updates a study
    Given I am a "User" user logged in as "abc123"
    Given I am visiting study "Study B" homepage
    Then I should not see "Manage"

  @javascript
  Scenario: Administrator edits study properties
    Given I am an "administrator" user logged in as "xyz1"
    Given I am visiting study "Study B" homepage
    When I follow "Manage"
    Then I should see "Manage Study Study B"
    And the field labeled "HMDMC approved" should be disabled
    And the field labeled "HuMFre approval number" should contain ""
    When I fill in "HuMFre approval number" with "XX/XXX"
    And I press "Update"
    Then I should see "Your study has been updated"
    And the field labeled "HuMFre approval number" should contain "XX/XXX"
    When I press "Update"
    Then I should see "Your study has been updated"

  @javascript
  Scenario: Data access coordinator edits study properties
    Given I am an "data_access_coordinator" user logged in as "xyz1"
    And user "xyz1" is an administrator
    Given I am visiting study "Study B" homepage
    When I follow "Manage"
    Then I should see "Manage Study Study B"
    And the field labeled "HMDMC approved" should not be disabled
    And the checkbox labeled "HMDMC approved" should not be checked
    When I check "HMDMC approved"
    And I press "Update"
    Then I should see "Your study has been updated"
    And the checkbox labeled "HMDMC approved" should be checked
    When I press "Update"
    Then I should see "Your study has been updated"

  @javascript
  Scenario: Administrator edits study ethical approval
    Given I am an "administrator" user logged in as "xyz1"
    Given I allow redirects and am on the show page for study "Study B"
    And I follow "Manage"
    When I attach the relative file "test/data/blah.fasta" to "study_uploaded_data"
    And I press "Update"
    Then I should see "Your study has been updated"
    And I should see "Listing 1 document"
    And I should see "blah.fasta"
    When I attach the relative file "test/data/very_small_file" to "study_uploaded_data"
    And I press "Update"
    Then I should see "Your study has been updated"
    And I should see "Listing 2 documents"
    And I should see "very_small_file"
    When I delete the attached file "very_small_file"
    Then I should see "Document was successfully deleted"
    And I should see "Listing 1 document"
    And I should see "blah.fasta"
    And I should not see "very_small_file"
