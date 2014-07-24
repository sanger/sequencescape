@javascript @study @creation @study_bam
Feature: Study creation with a checkbox for BAM file.

  Background:
   Given I am a "administrator" user logged in as "user"
   When I go to the homepage
   Given a faculty sponsor called "Jack Sponsor" exists


  Scenario: A study is created with a BAM property as true
    When I follow "Create study"
    Then I should be on the new study page
    Then I should see "CREATE STUDY"
    Then I should see "Alignments in BAM"
    And the checkbox labeled "Alignments in BAM" should be checked
    When I uncheck "Alignments in BAM"
    Then the checkbox labeled "Alignments in BAM" should not be checked
    When I fill in the following:
      | Study name                 | new study     |
      | Study description          | writing cukes |
      | ENA Study Accession Number | 12345         |
      | Study name abbreviation    | CCC3          |
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I select "Yes" from "Do any of the samples in this study contain human DNA?"
    And I select "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I select "No" from "Does this study require the removal of X chromosome and autosome sequence?"
    And I select "open" from "What is the data release strategy for this study?"
    When I press "Create"
    Then I should be on the study workflow page for "new study"
    Then abbreviation for Study "new study" should be "CCC3"
    Then I should see "Edit"
    When I follow "Edit"
    Then I should see "Alignments in BAM"
    And the checkbox labeled "Alignments in BAM" should not be checked

