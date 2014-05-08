@pipeline
Feature: Change pipeline inbox view about attribute "Concentration". Added request_information_type.

  Background:
    Given I am a "administrator" user logged in as "John Smith"

  Scenario: Library prep page
    Given Pipeline "Illumina-C Library preparation" and a setup for 6218053
    Given I am on the show page for pipeline "Illumina-C Library preparation"
    Then I should see "Library type"

  Scenario: Mx Library page
    Given Pipeline "Illumina-B MX Library Preparation" and a setup for 6218053
    Given I am on the show page for pipeline "Illumina-B MX Library Preparation"
    Then I should see "Library type"
    And I should see "Concentration"
