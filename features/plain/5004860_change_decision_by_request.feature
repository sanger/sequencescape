# rake features FEATURE=features/plain/5004860_change_decision_by_request.feature
Feature: Change decision for request state, asset qc_state and refund billing
  Background:                      
    Given sequencescape is setup for 5004860
    Given I am logged in as "John Doe"
    And I am an administrator
    When I go to the request page for the last request
    And I follow "Change decision"
    Then I should see "Change decision"
    And I should see "Request State"
  
  Scenario: No input -> Error
    When I press "Save changes"
    Then I should see "Checkboxes at least one must be selected"

  Scenario: Select to change Request State, not selected the value of combobox -> Error 
    When I check "Request State Checkbox"
    And I press "Save changes"
    Then I should see "State can't be blank"

  Scenario: Select an option, select a combobox value, not fill comment -> Error 
    When I check "Request State Checkbox"
    And I select "passed" from "Request State Available" 
    When I press "Save changes"
    Then I should see "Comment can't be blank"
      
  Scenario: Case Request State changed correctly.
    When I check "Request State Checkbox"
    And I select "passed" from "Request State Available"
    And I fill in "Reason for this action:" with "User Smith asked to modify this status" 
    When I press "Save changes"
    Then I should see "passed"
    And I should see "Update. Below you find the new situation."
  
  Scenario: Select to change Asset QC State, not selected the value of combobox -> Error 
    When I check "Asset QC State Checkbox"
    And I press "Save changes"
    Then I should see "Asset qc state can't be blank"

  Scenario: Select to change Asset QC State, select a combobox value, not fill comment -> Error 
    When I check "Asset QC State Checkbox"
    And I select "pending" from "Asset QC State Available"
    And I fill in "Reason for this action:" with "User Smith asked to modify this status"  
    When I press "Save changes"
    Then I should see "Asset qc state cannot be same as current state"

  Scenario: Select to change Asset QC State, select a combobox value, not fill comment -> Error 
    When I check "Asset QC State Checkbox"
    And I select "passed" from "Asset QC State Available" 
    When I press "Save changes"
    Then I should see "Comment can't be blank"

  Scenario: Case Select to change Asset QC State changed correctly.
    When I check "Asset QC State Checkbox"
    And I select "failed" from "Asset QC State Available"
    And I fill in "Reason for this action:" with "User Smith asked to modify this status" 
    When I press "Save changes"
    Then I should see "failed"
    And I should see "Update. Below you find the new situation."
  
  Scenario: Select to change Billing State, select a combobox value, not fill comment -> Error
    When I check "Billing Checkbox"
    And I select "refund" from "Billing State Available" 
    And I fill in "Description for billing event:" with "Refund as asked user YXZ"
    And I fill in "Reason for this action:" with "User Smith asked to modify this status"
    When I press "Save changes"
    Then I should see "Update. Below you find the new situation."

  Scenario: Case Complete.
    When I check "Request State Checkbox"
    And I select "passed" from "Request State Available"
    And I check "Asset QC State Checkbox"
    And I select "failed" from "Asset QC State Available"
    And I check "Billing Checkbox"
    And I select "refund" from "Billing State Available" 
    And I fill in "Description for billing event:" with "Refund as asked user YXZ"
    And I fill in "Reason for this action:" with "User Smith asked to modify this status" 
    When I press "Save changes"
    Then I should see "passed"
    And I should see "refund"
    And I should see "Update. Below you find the new situation."
