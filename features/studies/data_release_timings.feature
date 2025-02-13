@javascript @study @data_release
Feature: Studies have timings for release of their data
  Background:
    Given a faculty sponsor called "Jack Sponsor" exists
    Given I am an "administrator" user logged in as "John Smith"
    Given I am on the study creation page
    And I fill in "Study name" with "Testing data release strategies"
    And I select "Jack Sponsor" from "Faculty Sponsor"
    And I select "General" from "Program"
    And I select "Clone Sequencing" from "Study Type"
    And I select "WGS" from "EBI Library Strategy"
    And I select "GENOMIC" from "EBI Library Source"
    And I select "PCR" from "EBI Library Selection"
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
    When I select "6 months" from "Delay for"
      And I press "Create"
    Then I should be on the study information page for "Testing data release strategies"
      And I should see "Your study has been created"

  Scenario: When the data release is never but the prevention other comment is not supplied
    When I choose "Not Applicable" from "What is the data release strategy for this study?"
    And I select "never" from "How is the data release to be timed?"
    And I select "Other (please specify)" from "What is the reason for preventing data release?"
    And I fill in "If reason for exemption requires DAC approval, what is the approval number?" with "12345"
    When I press "Create"
    Then I should be on the studies page
    # Again, ideally without study metadata
    And I should see "Study metadata data release prevention other comment can't be blank"

  Scenario: When the data release is never and the prevention other comment is supplied
    When I choose "Not Applicable" from "What is the data release strategy for this study?"
    And I select "never" from "How is the data release to be timed?"
    And I select "Other (please specify)" from "What is the reason for preventing data release?"
    And I fill in "Please explain the reason for preventing data release" with "Some reason"
    And I fill in "If reason for exemption requires DAC approval, what is the approval number?" with "12345"
    When I press "Create"
    Then I should be on the study information page for "Testing data release strategies"
    And I should see "Your study has been created"

  Scenario: When the data release is never and the prevention comment is supplied
    When I choose "Not Applicable" from "What is the data release strategy for this study?"
    And I select "never" from "How is the data release to be timed?"
    And I select "Protecting IP - DAC approval required" from "What is the reason for preventing data release?"
    And I fill in "If reason for exemption requires DAC approval, what is the approval number?" with "12345"
    When I press "Create"
    Then I should be on the study information page for "Testing data release strategies"
    And I should see "Your study has been created"
