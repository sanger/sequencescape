@study @javascript @data_release @study_data_release
Feature: Update the data release fields for creating a study

  Background:
    Given I am a "manager" user logged in as "user"
    Given a faculty sponsor called "Jack Sponsor" exists
    And I am on the new study page

  Scenario: Add help text to study description (8348119)
    Then the help text for "Study description help text" should contain:
      """
      Please choose one of the following 2 standard statements to be included with your data submissions (one or the other, depending on the study). If you use the second statement, replace [doi or ref] by a reference or doi for your publication:

      This data is part of a pre-publication release. For information on the proper use of pre-publication data shared by the Wellcome Trust Sanger Institute (including details of any publication moratoria), please see http://www.sanger.ac.uk/datasharing/

      OR

      This data has been described in the following article [doi or ref] and its further analysis can be freely submitted for publication. For information on the proper use of data shared by the Wellcome Trust Sanger Institute (including information on acknowledgement), please see http://www.sanger.ac.uk/datasharing/
      """

  Scenario Outline: Add help text opposite delay drop down (4044305)
    When I select "<release strategy>" from "What is the data release strategy for this study?"
    When I select "delayed" from "How is the data release to be timed?"
    Then the help text for "Reason for delaying release help text" should contain:
      """
      To apply for a delay, please send the following information to John Doe (foo):
      SAC sponsor
      Study title and, where available, data set(s) ID
      Study description (should describe the data types that will be produced)
      Data sharing plan (to include the following):
      - Which repository/repositories will be used
      - If data will be made available under a managed access mechanism
      - When data will be shared
      Reason(s) for delaying data release
      """

    Examples:
      | release strategy |
      | managed          |
      | open             |

  Scenario: Add help text to has this been approved for never release (4044343)
    When I select "not applicable" from "What is the data release strategy for this study?"
    When I select "never" from "How is the data release to be timed?"
    Then the help text for "Has this been approved? help text" should contain:
      """
      If this is for data validity reasons: approval from the sponsor is required
      If this is for legal reasons: approval from the Data Sharing Committee is required (please contact sd4)
      """

  Scenario Outline: Delaying for 3 months should have the same questions as all other delays (4044273)
    When I select "delayed" from "How is the data release to be timed?"
    And I select "other" from "Reason for delaying release"
    And I select "<delay_period>" from "Delay for"
    Then I should exactly see "Has the delay period been approved by the data sharing committee for this project?"
    And I should exactly see "Comment regarding data release timing and approval"

    When I fill in the following:
        | Study name                                                                                  | new study       |
        | Study description                                                                           | writing cukes   |
        | Please explain the reason for delaying release (e.g., pre-existing collaborative agreement) | some comment    |
        | Comment regarding data release timing and approval                                          | another comment |
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I select "Yes" from "Do any of the samples in this study contain human DNA?"
    And I select "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I select "open" from "What is the data release strategy for this study?"
    When I press "Create"
    Then I should be on the study workflow page for "new study"

    Examples:
      | delay_period |
      | 3 months     |
      | 12 months    |
