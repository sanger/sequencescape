@barcode-service @barcode @sample_tube @asset @printing @sample_tube_printing
Feature: Print truncated sanger sample id on sample tube barcode

  Background:
    Given I am a "manager" user logged in as "john"
    And a robot exists
    And I have a "Illumina-C - Library creation - Paired end sequencing" submission with 1 sample tubes as part of "Test study" and "Test project"
    And the "1D Tube" barcode printer "xyz" exists
    Given I am on the show page for pipeline "Illumina-C Library preparation"
    And I check "Select NT1O for batch"
    And I press the first "Submit"
    And I follow "Print labels"
    And 1 pending delayed jobs are processed

  Scenario: Print a barcode for an asset with a sample without a sanger_sample_id
    Given the child asset of "Sample Tube 1" has a sanger_sample_id of ""
    When Pmb has the required label templates
    And I print the following labels
      | Field                 | Value             |
      |top_line               | Sample Tube 1 \d+ |
      |middle_line            | \d+               |
      |round_label_top_line   | NT                |
      |round_label_bottom_line| \d+               |
    Then I should see "Your 1 label(s) have been sent to printer xyz"

  Scenario: Print a barcode for an asset with a sample with a short sanger_sample_id
    Given the child asset of "Sample Tube 1" has a sanger_sample_id of "TW123456"
    When Pmb has the required label templates
    And I print the following labels
      | Field                 | Value             |
      |top_line               | TW123456          |
      |middle_line            | \d+               |
      |round_label_top_line   | NT                |
      |round_label_bottom_line| \d+               |
    Then I should see "Your 1 label(s) have been sent to printer xyz"

  Scenario: Print a barcode for an asset with a long sanger_sample_id
    Given the child asset of "Sample Tube 1" has a sanger_sample_id of "UK10K_Twins1234567"
    When Pmb has the required label templates
    And I print the following labels
      | Field                 | Value             |
      |top_line               | 1234567           |
      |middle_line            | \d+               |
      |round_label_top_line   | NT                |
      |round_label_bottom_line| \d+               |
    Then I should see "Your 1 label(s) have been sent to printer xyz"

