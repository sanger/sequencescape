@study @javascript @data_release @study_data_release
Feature: Update the data release fields for creating a study

  Background:
    Given I am a "manager" user logged in as "user"
    Given a faculty sponsor called "Jack Sponsor" exists
    And I am on the new study page

  Scenario Outline: Add help text opposite delay drop down (4044305)
    When I choose "<release strategy>" from "What is the data release strategy for this study?"
    When I select "delayed" from "How is the data release to be timed?"
    When I select "Other (please specify below)" from "Reason for delaying release"
    Then I should exactly see "Reason for delaying release"

    Examples:
      | release strategy |
      | Managed (EGA)    |
      | Open (ENA)       |

  Scenario Outline: Delaying for 3 months should have the same questions as all other delays (4044273)
    When I select "delayed" from "How is the data release to be timed?"
    And I select "Other (please specify below)" from "Reason for delaying release"
    And I select "<delay_period>" from "Delay for"

    When I fill in the following:
      | Study name                                         | new study       |
      | Study description                                  | writing cukes   |
      | Please explain the reason for delaying release     | some comment    |

    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I select "General" from "Program"
    And I select "WGS" from "EBI Library Strategy"
    And I select "GENOMIC" from "EBI Library Source"
    And I select "PCR" from "EBI Library Selection"
    And I choose "Yes" from "Do any of the samples in this study contain human DNA?"
    And I choose "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I choose "Yes" from "Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?"
    And I choose "Open (ENA)" from "What is the data release strategy for this study?"
    When I press "Create"
    Then I should be on the study information page for "new study"

    Examples:
      | delay_period |
      | 3 months     |
      | 12 months    |
