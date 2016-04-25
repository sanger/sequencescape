@barcode-service @barcode @sample_tube @asset @printing @sample_tube_printing
Feature: Print truncated sanger sample id on sample tube barcode

  Background:
    Given I am a "manager" user logged in as "john"
    And a robot exists
    And I have a "Illumina-C - Library creation - Paired end sequencing" submission with 1 sample tubes as part of "Test study" and "Test project"
    And the "1D Tube" barcode printer "xyz" exists
    Given I am on the show page for pipeline "Illumina-C Library preparation"
    And I check "Select SampleTube 1 for batch"
    And I press the first "Submit"
    And I follow "Print labels"
    And 1 pending delayed jobs are processed

  Scenario: Print a barcode for an asset with a sample without a sanger_sample_id
    Given the child asset of "Sample Tube 1" has a sanger_sample_id of ""
    When I press "Print labels"
    Then the last printed label should contains:
      | Field | Value |
      | name  | NT \d+|
      | desc  | Sample Tube 1 \d+_\d+ |

  Scenario: Print a barcode for an asset with a sample with a short sanger_sample_id
    Given the child asset of "Sample Tube 1" has a sanger_sample_id of "TW123456"
    When I press "Print labels"
    Then the last printed label should contains:
      | Field | Value |
      | name  | NT \d+       |
      | desc  | TW123456_\d+ |

  Scenario: Print a barcode for an asset with a long sanger_sample_id
    Given the child asset of "Sample Tube 1" has a sanger_sample_id of "UK10K_Twins1234567"
    When I press "Print labels"
    Then the last printed label should contains:
      | Field | Value |
      | name  | NT \d+       |
      | desc  | 1234567_\d+ |

