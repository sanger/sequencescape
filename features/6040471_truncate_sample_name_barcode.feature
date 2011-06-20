@barcode @asset_group @sample_tube @asset @printing @barcode-service
Feature: Print truncated sanger sample id on sample tube barcode

  Background:
    Given I am a "manager" user logged in as "john"
    And I have a study called "Test Study"
    And user "john" is a "manager" of study "Test Study"
    And I have an asset group "Test asset group" which is part of "Test Study"
    Given I am on the show page for study "Test Study"
    And the "96 Well Plate" barcode printer "xyz" exists
    When I follow "Asset groups"

  Scenario: Print a barcode for an asset with no name set
    Given asset group "Test asset group" contains a "SampleTube" called ""
    When I print the labels in the asset group
    Then the last printed label should contains:
      | Field | Value |
      | desc  | _17       |
      | name  | NT 17       |
      | prefix  | NT       |

  Scenario: Print a barcode for an asset with no sample
    Given asset group "Test asset group" contains a "SampleTube" called "Test Sample Tube"
    When I print the labels in the asset group
    Then the last printed label should contains:
      | Field | Value |
      | name  | NT 17       |
      | desc  | Test Sample Tube_17 |


  Scenario: Print a barcode for an asset with a sample without a sanger_sample_id
    Given asset group "Test asset group" contains a "SampleTube" called "Test Sample Tube"
    And the asset called "Test Sample Tube" has a sanger_sample_id of ""
    When I print the labels in the asset group
    Then the last printed label should contains:
      | Field | Value |
      | name  | NT 17       |
      | desc  | Test Sample Tube_17 |

  Scenario: Print a barcode for an asset with a sample with a short sanger_sample_id
    Given asset group "Test asset group" contains a "SampleTube" called "Test Sample Tube"
    And the asset called "Test Sample Tube" has a sanger_sample_id of "TW123456"
    When I print the labels in the asset group
    Then the last printed label should contains:
      | Field | Value |
      | name  | NT 17       |
      | desc  | TW123456_17 |

  Scenario: Print a barcode for an asset with a long sanger_sample_id
    Given asset group "Test asset group" contains a "SampleTube" called "Test Sample Tube"
    And the asset called "Test Sample Tube" has a sanger_sample_id of "UK10K_Twins1234567"
    When I print the labels in the asset group
    Then the last printed label should contains:
      | Field | Value |
      | name  | NT 17       |
      | desc  | 1234567_17 |

