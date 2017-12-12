@sample @sample_workflow
Feature: The various sample views should not be filtered by the users workflow
  Background:
    Given I am an "administrator" user logged in as "John Smith"
    And I have an active study called "Testing filtering sample views"

  # NOTE: Checking for the fields themselves, not the headers!
  Scenario: Sample registration views
    Given I am on the page for choosing how to register samples for study "Testing filtering sample views"
    And I follow "1. Manual entry"
    Then the fields listed below should be displayed:
      |field                           |
      |Cohort for sample 0             |
      |Gender for sample 0             |
      |Country of origin for sample 0  |
      |Geographical region for sample 0|
      |Ethnicity for sample 0          |
      |DNA source for sample 0         |
      |Volume (µl) for sample 0        |
      |Plate for sample 0              |
      |Mother for sample 0             |
      |Father for sample 0             |
      |Replicate for sample 0          |
      |Organism for sample 0           |
      |GC content for sample 0         |

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
