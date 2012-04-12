@sample
Feature: Patients should be able to withdraw consent
  So as to track withdraw of consent
  Samples should be able to be flagged as withdrawn
  This should be presented to downstream users
  
  Background:
    Given I am an "Manager" user logged in as "user"
    And I have an active study called "Study A"
    And user "user" is a "manager" of study "Study A"
    And I have an "approved" project called "Project A"
    And the project "Project A" has quotas and quotas are enforced
    And the study "Study A" has the sample "sample_withdrawn" in a sample tube and asset group
    And the study "Study A" has the sample "sample_okay" in a sample tube and asset group
    And the patient has withdrawn consent for "sample_withdrawn"

  Scenario: Withdrawn consent is presented downstream
    When I am on the samples page for study "Study A"
    Then I should see "Consent withdrawn" within ".withdrawn"
    And I should see "sample_withdrawn" within ".withdrawn"
    And I should not see "sample_okay" within ".withdrawn"
    When I am on the show page for sample "sample_okay"
    Then I should not see "Patient consent has been withdrawn for this sample."
    When I am on the show page for sample "sample_withdrawn" 
    Then I should see "Patient consent has been withdrawn for this sample."
