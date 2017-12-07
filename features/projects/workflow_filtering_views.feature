@project @project_workflow
Feature: The various project views should be filtered by the users workflow
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario: Project creation
    Given I am on the project creation page
    Then the fields listed below should be displayed:
      |field                           |
      |Sequencing Project Manager      |
      |Funding comments                |
      |Collaborators                   |
      |External funding source         |
      |Genotyping committee Tracking ID|

