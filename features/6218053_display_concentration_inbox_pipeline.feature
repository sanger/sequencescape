@pipeline
Feature: Change pipeline inbox view about attribute "Concentration". Added request_information_type.

  Background:
    Given I am a "administrator" user logged in as "John Smith"

  Scenario: Library prep page
    Given Pipeline "Library preparation" and a setup for 6218053
    Given I am on the show page for pipeline "Library preparation"
    Then I should see "Library type"

  Scenario: Mx Library page
    Given Pipeline "MX Library Preparation [NEW]" and a setup for 6218053
    Given I am on the show page for pipeline "MX Library Preparation [NEW]"
    Then I should see "Library type"
    And I should see "Concentration"
                                