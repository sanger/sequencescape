@study @study_required
Feature: Creating studies
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario: The required fields are required and study creation is on the homepage
    When I follow "Create study"
    Then I should be on the study creation page
    Then I should see the following required fields:
      | field                                                                                                         | type                                                                                       |
      | Study name                                                                                                    | text                                                                                       |
      | Faculty Sponsor                                                                                               | select                                                                                     |
      | Study description                                                                                             | textarea                                                                                   |
      | Do any of the samples in this study contain human DNA?                                                        | Yes/No                                                                                     |
      | Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis? | Yes/No                                                                                     |
      | Does this study require the removal of X chromosome and autosome sequence?                                    | Yes/No                                                                                     |
      | What is the data release strategy for this study?                                                             | open/managed                                                                               |
      | Study Visibility                                                                                              | Hold/Public                                                                                |
      | What sort of study is this?                                                                                   | genomic sequencing/transcriptomics/other sequencing-based assay/genotyping or cytogenetics |
      | How is the data release to be timed?                                                                          | standard/immediate/delayed/never                                                           |

    When I press "Create"
    Then I should be on the studies page
    And I should see "Name can't be blank"
    And I should see "Study description can't be blank"
    And I should see "Faculty sponsor can't be blank"
    # The rest of the fields are selections so can't be set to anything else!

  Scenario: Error messages do not show up on subsequent pages
    Given I am on the study creation page
    And I press "Create"
    Then I should be on the studies page
    And I should see "Problems creating your new study"

    When I follow "Studies"
    Then I should be on the studies page
    And I should not see "Problems creating your new study"
