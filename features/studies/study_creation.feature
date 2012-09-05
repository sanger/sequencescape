@study @creation @javascript
Feature: Study creation
  So sequencing on DNA samples can be requested
  And tracked by users, managers and administrative staff
  Users with privilege
  need to create studies first

  Background:
   Given I am a "administrator" user logged in as "user"
   Given a faculty sponsor called "Jack Sponsor" exists
   When I go to the homepage
   When I follow "Create study"
   Then I should be on the new study page
   Then I should see "CREATE STUDY"
   Then I should see "Properties"

  Scenario: A study is created with an abbreviation set
    When I fill in the following:
      | Study name                 | new study     |
      | Study description          | writing cukes |
      | ENA Study Accession Number | 12345         |
      | Study name abbreviation    | CCC3          |
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I select "Yes" from "Do any of the samples in this study contain human DNA?"
    And I select "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I select "open" from "What is the data release strategy for this study?"
    When I press "Create"
    Then I should be on the study workflow page for "new study"
    Then abbreviation for Study "new study" should be "CCC3"

  Scenario: An abbreviation is not set for the study
    When I fill in the following:
      | Study name                 | new study     |
      | Study description          | writing cukes |
      | ENA Study Accession Number | 12345         |

    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I select "Yes" from "Do any of the samples in this study contain human DNA?"
    And I select "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I select "open" from "What is the data release strategy for this study?"
    When I press "Create"
    Then I should be on the study workflow page for "new study"
    Then abbreviation for Study "new study" should be "[\d]+STDY"
