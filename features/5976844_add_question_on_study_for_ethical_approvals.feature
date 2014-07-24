@study @creation @javascript @commercially_available
Feature: Added property "commercially_available". Add and edit this value. Pending ethical approval menu.

  Background:
   Given I am a "administrator" user logged in as "user"
   When I go to the homepage


  Scenario Outline: A study is created and it appears in Pending ethical approval true
    Given a faculty sponsor called "Jack Sponsor" exists
    When I follow "Create study"
    Then I should be on the new study page
    Then I should see "CREATE STUDY"
    Then I should see "Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?"
    When I fill in the following:
      | Study name                 | new study     |
      | Study description          | writing cukes |
      | ENA Study Accession Number | 12345678      |
      | Study name abbreviation    | CCC3435       |
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I select "<contain_dna>" from "Do any of the samples in this study contain human DNA?"
    And I select "<contaminated_dna>" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I select "<commercial>" from "Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?"
    And I select "open" from "What is the data release strategy for this study?"
    When I press "Create"
    Then I should be on the study workflow page for "new study"
    Then abbreviation for Study "new study" should be "CCC3435"
    When I follow "Studies"
    Then I should see "Pending ethical approval"
    When I follow "Pending ethical approval"
    Then I should see "<should_see>"

    Examples:
      | contain_dna  | contaminated_dna | commercial | should_see |
      | Yes          | No               | No         | new study  |
      | Yes          | No               | Yes        |            |
      | Yes          | Yes              | No         |            |
      | Yes          | Yes              | Yes        |            |
      | No           | No               | No         |            |
      | No           | No               | Yes        |            |
      | No           | Yes              | No         |            |
      | No           | Yes              | Yes        |            |



