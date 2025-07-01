@study @faculty_sponsor
Feature: Manage a list of faculty sponsors

  @admin
  Scenario: Add and update a faculty sponsor
    Given I am a "administrator" user logged in as "user"
      And I am on the faculty sponsor homepage
    Then I should see "Faculty Sponsors"
    When I follow "New Faculty Sponsor"
      And I fill in "Name" with "Johnny Smith"
      And I press "Create"
    Then I should see "Faculty Sponsor was successfully created"
      And I should be on the faculty sponsor homepage
      And I should see "Johnny Smith"
    When I follow "Edit Johnny Smith"
    Then I should see "Faculty Sponsor"
    When I fill in "Name" with "Jane Doe"
      And I press "Update"
    Then I should see "Faculty Sponsor was successfully updated"
      And I should be on the faculty sponsor homepage
      And I should see "Jane Doe"
      And I should not see "Johnny Smith"
    When I follow "Delete Jane Doe"
    Then I should see "Faculty Sponsor was successfully deleted"
      And I should not see "Jane Doe"

  @admin
  Scenario: List the studies associated with a Faculty Sponsor
    Given a faculty sponsor called "Adam Apple" exists
      And a faculty sponsor called "Barry Ball" exists
      And a faculty sponsor called "Conor Cone" exists
      And I am a "administrator" user logged in as "user"
      And I am on the faculty sponsor homepage
    Then the faculty sponsor index page should include:
      | Name       | Number of Studies |
      | Adam Apple | 0                 |
      | Barry Ball | 0                 |
      | Conor Cone | 0                 |

    Given I create study "Big study" with faculty sponsor "Barry Ball"
      And I create study "Another Big study" with faculty sponsor "Barry Ball"
      And I create study "Small study" with faculty sponsor "Conor Cone"
      And I am on the faculty sponsor homepage
    Then the faculty sponsor index page should include:
      | Name       | Number of Studies |
      | Adam Apple | 0                 |
      | Barry Ball | 2                 |
      | Conor Cone | 1                 |

    When I follow "View Barry Ball"
    Then the list of studies should be:
      | Study name        |
      | Big study         |
      | Another Big study |

  @admin
  Scenario: Create a sponsor and use it to create a study
    Given I am a "administrator" user logged in as "user"
      And I am on the faculty sponsor homepage
    When I follow "New Faculty Sponsor"
      And I fill in "Name" with "John Doe"
      And I press "Create"
    Given I am on the homepage
    When I follow "Create Study"
      And I fill in "Study name" with "Study name"
      And I select "Not suitable for alignment" from "Reference genome"
      And I fill in "Study description" with "some description"
      And I select "General" from "Program"
      And I select "WGS" from "EBI Library Strategy"
      And I select "GENOMIC" from "EBI Library Source"
      And I select "PCR" from "EBI Library Selection"
      And I fill in "Data access group" with "dag"
      And I select "John Doe" from "Faculty Sponsor"
      And I choose "Yes" from "Do any of the samples in this study contain human DNA?"
      And I choose "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
      And I choose "Yes" from "Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?"
      And I choose "Open (ENA)" from "What is the data release strategy for this study?"
      And I press "Create"
    Then I should see "Your study has been created"
    When I follow "Study details"
    Then I should see "John Doe"

  Scenario: Update the faculty sponsor on an existing study
    Given a faculty sponsor called "Jack Sponsor" exists
    Given I am a "administrator" user logged in as "user"
      And I have an active study called "Test study"
      And I am on the show page for study "Test study"
    When I follow "Study details"
    Then I should see "John Doe"
    When I follow "Edit"
      And I select "Jack Sponsor" from "Faculty Sponsor"
      And I press "Save Study"
    Then I should see "Your study has been updated"
    When I follow "Study details"
    Then I should see "Jack Sponsor"

  Scenario Outline: Only admins can manage faculty sponsors
    Given I am a "<role>" user logged in as "user"
      And I am on the faculty sponsor homepage
    Then I should see "Sorry, you are not authorized to index this Faculty sponsor"
    Examples:
      | role          |
      | follower      |
      | internal      |
      | lab           |
      | lab_manager   |
      | manager       |
      | owner         |
      | slf_gel       |
      | slf_manager   |
