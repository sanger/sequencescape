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
    Then I should see "Create Study"
    When I follow "Create Study"
    And I fill in "study_name" with "Cucumber1"
    Then I should see the required select field "Reference genome" with the option "Mus_musculus (NCBIm37)"
    And I choose "Yes" from "Do any of the samples in this study contain human DNA?"
    And I choose "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I choose "Yes" from "Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?"
    And I choose "Open (ENA)" from "What is the data release strategy for this study?"
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I select "General" from "Program"
    And I select "Clone Sequencing" from "Study Type"
    And I select "WGS" from "EBI Library Strategy"
    And I select "GENOMIC" from "EBI Library Source"
    And I select "PCR" from "EBI Library Selection"
    And I fill in "Study description" with "parp parp"
    And I fill in "Data access group" with "dag"
    And I press "Create"
    Then I should see "Your study has been created"

