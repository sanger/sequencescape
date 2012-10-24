# rake features FEATURE=features/plain/projects/project_creation.feature
@project @project_creation
Feature: Creating projects
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario Outline: From various pages I should be able to create a project
    Given I am on the <start_page>
    When I follow "<link>"
    Then I should be on the project creation page

    Examples:
      |start_page   |link          |
      |homepage     |Create project|
      |projects page|New Project   |

  Scenario: The required fields are required
    Given I am on the project creation page
    Then I should see the following required fields:
      |field|type|
      |Name|text|
      |Project cost code|text|
      |Sequencing Project Manager|select|
      |Sequencing budget division|select|

    When I press "Create"
    Then I should be on the projects page
    And I should see "Name can't be blank"
    And I should see "Project cost code can't be blank"
    # The rest of the fields are selections so can't be set to anything else!

  Scenario: Error messages do not show up on subsequent pages
    Given I am on the project creation page
    And I press "Create"
    Then I should be on the projects page
    And I should see "Problems creating your new project"

    When I follow "Projects"
    Then I should be on the projects page
    And I should not see "Problems creating your new project"

  Scenario: Creating a microarray genotyping project
    Given user "John Smith" has a workflow "Microarray genotyping"

    Given I am on the project creation page
    And I fill in "Name" with "Testing project creation"
    And I fill in "Project cost code" with "Cost code 101"
    And I press "Create"

    Then I should be on the show page for project "Testing project creation"
    And I should see "Your project has been created"

    # NOTE: What follows may not be how it looks on the screen because the table is orderable with Javascript!
    And the project quotas table should be:
      | Request type                           | Total quota | Used quota | Remaining quota | Change quota |
      | Cherrypick                             | 0           | 0          | 0               | Request more |
      | DNA QC                                 | 0           | 0          | 0               | Request more |
      | Genotyping                             | 0           | 0          | 0               | Request more |

  Scenario: Creating a next-gen sequencing project
    Given user "John Smith" has a workflow "Next-gen sequencing"

    Given I am on the project creation page
    And I fill in "Name" with "Testing project creation"
    And I fill in "Project cost code" with "Cost code 101"
    And I press "Create"

    Then I should be on the show page for project "Testing project creation"
    And I should see "Your project has been created"

    # NOTE: What follows may not be how it looks on the screen because the table is orderable with Javascript!
    And the project quotas table should be:
      | Request type                           | Total quota | Used quota | Remaining quota | Change quota |
      | Cherrypicking for Pulldown             | 0           | 0          | 0               | Request more |
      | HiSeq Paired end sequencing            | 0           | 0          | 0               | Request more |
      | Illumina-B Multiplexed Library Creation| 0           | 0          | 0               | Request more |
      | Illumina-B STD                         | 0           | 0          | 0               | Request more |
      | Illumina-C Multiplexed Library Creation| 0           | 0          | 0               | Request more |
      | Library creation                       | 0           | 0          | 0               | Request more |
      | Multiplexed library creation           | 0           | 0          | 0               | Request more |
      | PacBio Sample Prep                     | 0           | 0          | 0               | Request more |
      | PacBio Sequencing                      | 0           | 0          | 0               | Request more |
      | Paired end sequencing                  | 0           | 0          | 0               | Request more |
      | Pulldown ISC                           | 0           | 0          | 0               | Request more |
      | Pulldown Multiplex Library Preparation | 0           | 0          | 0               | Request more |
      | Pulldown SC                            | 0           | 0          | 0               | Request more |
      | Pulldown WGS                           | 0           | 0          | 0               | Request more |
      | Pulldown library creation              | 0           | 0          | 0               | Request more |
      | Single ended hi seq sequencing         | 0           | 0          | 0               | Request more |
      | Single ended sequencing                | 0           | 0          | 0               | Request more |
