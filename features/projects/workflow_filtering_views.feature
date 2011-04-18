@project @project_workflow
Feature: The various project views should be filtered by the users workflow
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario Outline: Project creation
    Given user "John Smith" has a workflow "<workflow>"

    Given I am on the project creation page
    Then the "<workflow>" fields listed below should be appropriately displayed:
      |field                           | workflow              |
      |Sequencing Project Manager      | Next-gen sequencing   |
      |Funding comments                | Next-gen sequencing   |
      |Collaborators                   | Next-gen sequencing   |
      |External funding source         | Next-gen sequencing   |
      |Genotyping committee Tracking ID| Microarray genotyping |

    Examples:
      |workflow|
      |Next-gen sequencing|
      |Microarray genotyping|
