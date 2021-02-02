@sample @sample_workflow
Feature: The various sample views should not be filtered by the users workflow
  Background:
    Given I am an "administrator" user logged in as "John Smith"
    And I have an active study called "Testing filtering sample views"

  Scenario: Sample editing views
    And the sample named "testing_sample_edit" exists
    When I am on the edit page for sample "testing_sample_edit"
    Then the fields listed below should be displayed:
      |field               |
      |Cohort              |
      |Gender              |
      |Country of origin   |
      |Geographical region |
      |Ethnicity           |
      |DNA source          |
      |Volume (µl)         |
      |Plate               |
      |Mother              |
      |Father              |
      |Replicate           |
      |Organism            |
      |GC content          |
