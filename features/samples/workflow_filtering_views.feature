@sample @sample_workflow
Feature: The various sample views should not be filtered by the users workflow
  Background:
    Given I am an "administrator" user logged in as "John Smith"
    And I have an active study called "Testing filtering sample views"

  # NOTE: Checking for the fields themselves, not the headers!
  Scenario Outline: Sample registration views
    Given user "John Smith" has a workflow "<workflow>"

    Given I am on the page for choosing how to register samples for study "Testing filtering sample views"
    And I follow "1. Manual entry"
    Then the "<workflow>" fields listed below should be appropriately displayed:
      |field                           | workflow              |
      |Cohort for sample 0             | <workflow> |
      |Gender for sample 0             | <workflow> |
      |Country of origin for sample 0  | <workflow> |
      |Geographical region for sample 0| <workflow> |
      |Ethnicity for sample 0          | <workflow> |
      |DNA source for sample 0         | <workflow> |
      |Volume (µl) for sample 0        | <workflow> |
      |Plate for sample 0              | <workflow> |
      |Mother for sample 0             | <workflow> |
      |Father for sample 0             | <workflow> |
      |Replicate for sample 0          | <workflow> |
      |Organism for sample 0           | <workflow> |
      |GC content for sample 0         | <workflow> |

    Examples:
      |workflow|
      |Next-gen sequencing|
      |Microarray genotyping|

  Scenario Outline: Sample editing views
    Given user "John Smith" has a workflow "<workflow>"
    And the sample named "testing_sample_edit" exists

    When I am on the edit page for sample "testing_sample_edit"

    Then the "<workflow>" fields listed below should be appropriately displayed:
      |field               | workflow              |
      |Cohort              | <workflow> |
      |Gender              | <workflow> |
      |Country of origin   | <workflow> |
      |Geographical region | <workflow> |
      |Ethnicity           | <workflow> |
      |DNA source          | <workflow> |
      |Volume (µl)         | <workflow> |
      |Plate               | <workflow> |
      |Mother              | <workflow> |
      |Father              | <workflow> |
      |Replicate           | <workflow> |
      |Organism            | <workflow> |
      |GC content          | <workflow> |

    Examples:
      |workflow|
      |Next-gen sequencing|
      |Microarray genotyping|
