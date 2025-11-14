@barcode @asset_group @sample_tube @asset @printing @barcode-service
Feature: Print truncated sanger sample id on sample tube barcode

  Background:
    Given I am a "manager" user logged in as "john"
    And I have a study called "Test Study"
    And user "john" is a "manager" of study "Test Study"
    And I have an asset group "Test asset group" which is part of "Test Study"
    Given I allow redirects and am on the show page for study "Test Study"
    And the "1D Tube" barcode printer "xyz" exists
    When I follow "Asset groups"

  Scenario: Print a barcode for an asset with no name set
    Given asset group "Test asset group" contains a sample tube called ""
    When Pmb has the required label templates
    And I print the following labels in the asset group
      | Field                 | Value   |
      |first_line               |         |
      |second_line            | 17      |
      |round_label_top_line   | NT      |
      |round_label_bottom_line| 17      |
    Then I should see "Your 1 label(s) have been sent to printer xyz"

  Scenario: Print a barcode for an asset with no sample
    Given asset group "Test asset group" contains a sample tube called "Test Sample Tube"
    When Pmb has the required label templates
    And I print the following labels in the asset group
      | Field                 | Value            |
      |first_line               | Test Sample Tube |
      |second_line            | 17               |
      |round_label_top_line   | NT               |
      |round_label_bottom_line| 17               |
    Then I should see "Your 1 label(s) have been sent to printer xyz"

  Scenario: Print a barcode for an asset with a sample without a sanger_sample_id
    Given asset group "Test asset group" contains a sample tube called "Test Sample Tube"
    And the asset called "Test Sample Tube" has a sanger_sample_id of ""
    When Pmb has the required label templates
    And I print the following labels in the asset group
      | Field                 | Value            |
      |first_line               | Test Sample Tube |
      |second_line            | 17               |
      |round_label_top_line   | NT               |
      |round_label_bottom_line| 17               |
    Then I should see "Your 1 label(s) have been sent to printer xyz"

  Scenario: Print a barcode for an asset with a sample with a short sanger_sample_id
    Given asset group "Test asset group" contains a sample tube called "Test Sample Tube"
    And the asset called "Test Sample Tube" has a sanger_sample_id of "TW123456"
    When Pmb has the required label templates
    And I print the following labels in the asset group
      | Field                 | Value            |
      |first_line               | TW123456         |
      |second_line            | 17               |
      |round_label_top_line   | NT               |
      |round_label_bottom_line| 17               |
    Then I should see "Your 1 label(s) have been sent to printer xyz"

  Scenario: Print a barcode for an asset with a long sanger_sample_id
    Given asset group "Test asset group" contains a sample tube called "Test Sample Tube"
    And the asset called "Test Sample Tube" has a sanger_sample_id of "UK10K_Twins1234567"
    When Pmb has the required label templates
    And I print the following labels in the asset group
      | Field                 | Value            |
      |first_line               | 1234567          |
      |second_line            | 17               |
      |round_label_top_line   | NT               |
      |round_label_bottom_line| 17               |
    Then I should see "Your 1 label(s) have been sent to printer xyz"
