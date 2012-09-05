@study @admin
Feature: Study administration
    Owners and administrators can update the approval
    status for a study

  Background:
    Given I have an active study called "Study B"

  @focus @wip
  Scenario: Administrator views study contacts
    Given I am an "administrator" user logged in as "xyz1"
    Given I am visiting study "Study B" homepage
    When I follow "Contacts"
    Then I should see "Study B : Contacts"
    Then show me the page
    # And I should see the following contacts
    #   | role     | name       |
    #   | Owner    | John Smith |
    #   | Manager  | Mary Smith |
    #   | Follower | Lisa Smith |
    #   | Follower | Jack Smith |

  Scenario: User updates a study
    Given I am a "User" user logged in as "abc123"
    Given I am visiting study "Study B" homepage
    Then I should not see "Manage"

  @javascript
  Scenario: Administrator edits study properties
    Given I am an "administrator" user logged in as "xyz1"
    Given I am visiting study "Study B" homepage
    When I follow "Manage"
    Then I should see "Manage study: Study B"
    And the checkbox labeled "HMDMC approved" should not be checked
    And the field labeled "HMDMC approval number" should contain ""
    When I check "HMDMC approved"
    And I fill in "HMDMC approval number" with "XX/XXX"
    And I press "Update"
    Then I should see "Your study has been updated"
    And the checkbox labeled "HMDMC approved" should be checked
    And the field labeled "HMDMC approval number" should contain "XX/XXX"
    When I press "Update"
    Then I should see "Your study has been updated"

  @wip
  Scenario: Administrator edits study state
    Given I am visiting study "Study B" homepage
    When I follow "Manage"
    Then I should see "Manage study: Study B"
    And option "active" in the menu labeled "State" should be selected
    When I select "Inactive" from "State"
    And I press "Update"
    Then I should see "Your study has been updated"
    And option "inactive" in the menu labeled "State" should be selected
    When I select "Pending" from "State"
    And I press "Update"
    Then I should see "Your study has been updated"
    And option "pending" in the menu labeled "State" should be selected

  @javascript
  Scenario: Administrator edits study ethical approval
    Given I am an "administrator" user logged in as "xyz1"
    Given I am on the show page for study "Study B"
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
