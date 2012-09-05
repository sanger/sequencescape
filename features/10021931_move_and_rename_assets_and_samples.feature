@study @asset @sample @javascript @wip @to_fix @or_delete
Feature: Rename Asset and Sample
  Background:
    Given I am a "administrator" user logged in as "user"
    And I am on the homepage

  Scenario: the goal is rename sample and asset
    Given I have a study called "Study_PT_10021931"
    Given the sample named "Sample_10021931_Salmonella_1" exists
    Given the sample named "Sample_10021931_Salmonella_1" belongs to the study named "Study_PT_10021931"
    Given the asset "Asset_10021931_Salmonella_1" to the study named "Study_PT_10021931"
    Given the sample named "Sample_10021931_Salmonella_2" exists
    Given the sample named "Sample_10021931_Salmonella_2" belongs to the study named "Study_PT_10021931"
    Given the asset "Asset_10021931_Salmonella_2" to the study named "Study_PT_10021931"
    Given the sample named "Sample_10021931_Salmonella_3" exists
    Given the sample named "Sample_10021931_Salmonella_3" belongs to the study named "Study_PT_10021931"
    Given the asset "Asset_10021931_Salmonella_3" to the study named "Study_PT_10021931"
    Given the sample named "Sample_10021931_Salmonella_4" exists
    Given the sample named "Sample_10021931_Salmonella_4" belongs to the study named "Study_PT_10021931"
    Then I should see "Studies"
    When I follow "Studies"
    Then I should see "All"
    When I follow "All"
    Then I should see "Study_PT_10021931"
    When I follow "Study_PT_10021931"
    And I should see "Rename Assets and Samples"
    When I follow "Rename Assets and Samples"
    Then I should see "Sample_10021931_Salmonella_4"
    And I should see "Asset_10021931_Salmonella_2"
    When I check "Select ALL Samples"
    When I check "Select ALL Assets"
    And I fill in "Replace:" with "Salmonella"
    And I fill in "With:" with "Tuberculosis"
    When I press "Save changes"
    Then I should see "Update. Below you find the new situation."
    And I should see "Sample_10021931_Tuberculosis_2"
    And I should see "Asset_10021931_Tuberculosis_3"

  Scenario: The user doesn't fill properly the form
    Given I have a study called "Study_PT_10021931"
    Given the sample named "Sample_10021931_Salmonella_1" exists
    Given the sample named "Sample_10021931_Salmonella_1" belongs to the study named "Study_PT_10021931"
    Given the asset "Asset_10021931_Salmonella_1" to the study named "Study_PT_10021931"
    Then I should see "Studies"
    When I follow "Studies"
    Then I should see "All"
    When I follow "All"
    Then I should see "Study_PT_10021931"
    When I follow "Study_PT_10021931"
    When I follow "Rename Assets and Samples"
    Then I should see "Sample_10021931_Salmonella_1"
    And I should see "Asset_10021931_Salmonella_1"
    When I check "Select ALL Samples"
    When I check "Select ALL Assets"
    And I fill in "Replace:" with "Salmonella"
    When I press "Save changes"
    Then I should see "Failed! Please, read the list of problem below."
    And I should see "With can't be blank"
