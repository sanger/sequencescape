@reference_genome @admin
Feature: Add interface to update reference genomes

  Background:
    Given I am a "administrator" user logged in as "user"
    And I am on the homepage

  Scenario: Can I create a reference genome
    Then I should see "Admin"
    When I follow "Admin"
    Then I should see "Reference genome management"
    When I follow "Reference genome management"
    Then I should see "New reference genome"
    When I follow "New reference genome"
    When I fill in "Name" with "BlahBlahBlah"
    And I press "Create"
    Then I should see "Reference genome was successfully created."

  Scenario: Can I edit a reference genome
    Then I should see "Admin"
    When I follow "Admin"
    Then I should see "Reference genome management"
    When I follow "Reference genome management"
    Then I should see "New reference genome"
    When I follow "New reference genome"
    When I fill in "Name" with "WibbleWibble"
    And I press "Create"
    Then I should see "Reference genome was successfully created."
    When I follow "Edit"
    Then I should see "Editing reference genome"
    When I fill in "Name" with "WibbleWibble2"
    And I press "Update"
    Then I should see "Reference genome was successfully updated."
    When I follow "Back"
    Then I should see "Listing reference genomes"

  @javascript
  Scenario: Can I see and add a reference genome when creating a study
    Given a faculty sponsor called "Jack Sponsor" exists
    Given a reference genome table
    Then I should see "Studies"
    When I follow "Studies"
    Then I should see "Create study"
    When I follow "Create study"
    And I fill in "study_name" with "Cucumber1"
    Then I should see "Mus_musculus (NCBIm37)"

    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I fill in "Study description" with "parp parp"
    And I press "Create"
    Then I should see "Your study has been created"

