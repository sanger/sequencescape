@javascript @study @data_release
Feature: Studies have timings for release of their data
  Background:
    Given a faculty sponsor called "Jack Sponsor" exists
    Given I am an "administrator" user logged in as "John Smith"
    Given I am on the study creation page
    And I fill in "Study name" with "Testing data release strategies"
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I fill in "Study description" with "Checking that the data release strategies behave appropriately"
    And I choose "No" from "Do any of the samples in this study contain human DNA?"
    And I choose "No" from "Does this study contain samples that are contaminated with human DNA which must be removed prior to analysis?"
    And I choose "Yes" from "Are all the samples to be used in this study commercially available, unlinked anonymised cell-lines?"
    And I choose "Open (ENA)" from "What is the data release strategy for this study?"

  Scenario: When the data release is standard
    Given I select "standard" from "How is the data release to be timed?"
    When I press "Create"
    Then I should be on the study information page for "Testing data release strategies"
    And I should see "Your study has been created"


  Scenario: When the data release is immediate
    Given I select "immediate" from "How is the data release to be timed?"
    When I press "Create"
    Then I should be on the study information page for "Testing data release strategies"
    And I should see "Your study has been created"


  Scenario: When the data release is delayed for PhD study
    Given I select "delayed" from "How is the data release to be timed?"
      And I select "PhD study" from "Reason for delaying release"
    Then the "Comment regarding data release timing and approval" field is hidden
    When I select "6 months" from "Delay for"
      And I press "Create"
    Then I should be on the study information page for "Testing data release strategies"
      And I should see "Your study has been created"

  Scenario Outline: When the data release is delayed but no reasons are provided
    Given I select "delayed" from "How is the data release to be timed?"
    And I select "Other (with free text box)" from "Reason for delaying release"
    And I fill in "Please explain the reason for delaying release" with "Some reason"
    And I select "<period>" from "Delay for"
    When I press "Create"
    Then I should be on the studies page
    # Ideally this should be without the study metadata qualification
    And I should see "Study metadata data release delay reason comment can't be blank"

    Examples:
      | period    |
      | 3 months  |
      | 6 months  |
      | 9 months  |
      | 12 months |

  Scenario Outline: When the data release is delayed and the reasons are provided
    Given I select "delayed" from "How is the data release to be timed?"
    And I select "Other (with free text box)" from "Reason for delaying release"
    And I fill in "Please explain the reason for delaying release" with "Some reason"
    And I select "<period>" from "Delay for"
    And I fill in "Comment regarding data release timing and approval" with "Because it is ok?"
    When I press "Create"
    Then I should be on the study information page for "Testing data release strategies"
    And I should see "Your study has been created"

    Examples:
      | period    |
      | 3 months  |
      | 6 months  |
      | 9 months  |
      | 12 months |

  Scenario: When the data release is never but the comment is not supplied
    When I choose "Not Applicable" from "What is the data release strategy for this study?"
    And I select "never" from "How is the data release to be timed?"
    And I select "Protecting IP - DAC approval required" from "What is the reason for preventing data release?"
    And I fill in "If reason for exemption requires DAC approval, what is the approval number?" with "12345"
    When I press "Create"
    Then I should be on the studies page
    # Again, ideally without study metadata
    And I should see "Study metadata data release prevention reason comment can't be blank"

  Scenario: When the data release is never and the comment is supplied
    When I choose "Not Applicable" from "What is the data release strategy for this study?"
    And I select "never" from "How is the data release to be timed?"
    And I select "Protecting IP - DAC approval required" from "What is the reason for preventing data release?"
    And I fill in "Comment regarding prevention of data release and approval" with "Some reason"
    And I fill in "If reason for exemption requires DAC approval, what is the approval number?" with "12345"
    When I press "Create"
    Then I should be on the study information page for "Testing data release strategies"
    And I should see "Your study has been created"
