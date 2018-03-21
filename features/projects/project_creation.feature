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
      |homepage     |Create Project|
      |projects page|New Project   |

  Scenario: The required fields are required
    Given I am on the project creation page
    Then I should see the following required fields:
      |field                     |type  |
      |Name                      |text  |
      |Project cost code         |text  |

    # The fields below were tested as required
    # prior to the rails 3 upgrade. However the
    # test merely looked for ANY required field
    And I should see the following fields:
      |field                     |type  |
      |Sequencing Project Manager|select|
      |Sequencing budget division|select|

    When I press "Create"
    Then I should be on the projects page
    And I should see "Name can't be blank"
    And I should see "cost code can't be blank"
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


    Given I am on the project creation page
    And I fill in "Name" with "Testing project creation"
    And I fill in "Project cost code" with "Cost code 101"
    And I select "Internal" from "Project funding model"
    And I press "Create"

    Then I should be on the show page for project "Testing project creation"
    And I should see "Your project has been created"

  Scenario: Creating a next-gen sequencing project


    Given I am on the project creation page
    And I fill in "Name" with "Testing project creation"
    And I fill in "Project cost code" with "Cost code 101"
    And I select "Internal" from "Project funding model"
    And I press "Create"

    Then I should be on the show page for project "Testing project creation"
    And I should see "Your project has been created"

