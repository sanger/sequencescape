@submission
Feature: Weird submission link behaviour
    To avoid user confusion
    Links to create the first submission
    should be consistent with subsequent create submission links
    and should only appear when submissions can be created
    # NOTE: This feature will need to be revisited, due to
    # inconsistencies in the sidebar link code. Ideally the
    # two should behave the same.

  Background:
    Given I am an "administrator" user logged in as "admin"
    And I have an active study called "Study A"
    And I have a study called "Study B"
    And user "admin" is a "manager" of study "Study A"
    Given study "Study A" has a registered sample "Sample_A" with no submissions
    And user "admin" is a "manager" of study "Study B"
    Given study "Study B" has a registered sample "Sample_B" with no submissions

  Scenario: Create submission links to not appear on inactive studies
    Given I am visiting study "Study A" homepage
    Then I should see "There are no submissions on this study yet. Please create your first submission"
    And I should see "Create Submission"
    And I should not see "This study has not been activated yet."
    When I am visiting study "Study B" homepage
    Then I should not see "There are no submissions on this study yet. Please create your first submission"
    And I should not see "Create Submission"
    And I should see "This study has not been activated yet."

  Scenario: Create submission links to appear for non-manager administrators of the study
    Given I am an "administrator" user logged in as "Barry"
    And I am visiting study "Study A" homepage
    Then I should see "There are no submissions on this study yet. Please create your first submission"
    And I should see "Create Submission"
    And I should not see "This study has not been activated yet."

  Scenario: Create submission links do not appear for non admin managers of other studies
    Given I am a "manager" user logged in as "Colin"
    And I am visiting study "Study A" homepage
    Then I should not see "There are no submissions on this study yet. Please create your first submission"
    # NOTE: The following behaviour is undesirable in the long term.
    And I should see "Create Submission"
    And I should not see "This study has not been activated yet."