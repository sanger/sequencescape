@study @javascript @data_release @study_data_release
Feature: Update the data release fields for creating a study

  Background:
    Given I am a "manager" user logged in as "user"
    Given a faculty sponsor called "Jack Sponsor" exists
    And I am on the new study page

  Scenario: Add help text to study description (8348119)
    Then the help text for "Study description" should contain:
      """
      Please choose one of the following 2 standard statements to be included with your data submissions (one or the other, depending on the study). If you use the second statement, replace [doi or ref] by a reference or doi for your publication:

      This data is part of a pre-publication release. For information on the proper use of pre-publication data shared by the Wellcome Trust Sanger Institute (including details of any publication moratoria), please see http://www.sanger.ac.uk/datasharing/

      OR

      This data has been described in the following article [doi or ref] and its further analysis can be freely submitted for publication. For information on the proper use of data shared by the Wellcome Trust Sanger Institute (including information on acknowledgement), please see http://www.sanger.ac.uk/datasharing/
      If applicable, include a brief description of any restrictions on data usage, e.g. 'For AIDS-related research only'
      """

  Scenario Outline: Add help text opposite delay drop down (4044305)
    When I choose "<release strategy>" from "What is the data release strategy for this study?"
    When I select "delayed" from "How is the data release to be timed?"
    When I select "Other (please specify below)" from "Reason for delaying release"
    Then I should exactly see "Reason for delaying release"

    Examples:
      | release strategy |
      | Managed (EGA)    |
      | Open (ENA)       |

  Scenario: Add help text to has this been approved for never release (4044343)
    When I choose "Not Applicable" from "What is the data release strategy for this study?"
    When I select "never" from "How is the data release to be timed?"
    Then the help text for "If reason for exemption requires DAC approval, what is the approval number?" should contain:
      """
      If this is for data validity reasons: approval from the sponsor is required
      If this is for legal reasons: approval from the Data Sharing Committee is required (please contact sd4)
      """

  Scenario Outline: Delaying for 3 months should have the same questions as all other delays (4044273)
    When I select "delayed" from "How is the data release to be timed?"
    And I select "Other (please specify below)" from "Reason for delaying release"
    And I select "<delay_period>" from "Delay for"

    When I fill in the following:
      | Study name                                         | new study       |
      | Study description                                  | writing cukes   |
      | Please explain the reason for delaying release     | some comment    |

    And I select "Jack Sponsor" from "Faculty Sponsor"
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
