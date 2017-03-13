@cherrypicking @javascript @barcode-service @study_report
Feature: Cherrypicking a plate twice should display latest plate in report

  Background:
    Given I am a "administrator" user logged in as "user"
    Given I have a project called "Test project"

    Given I have an active study called "Test study"
    Given I have a "Stock Plate" plate "1234567" in study "Test study" with 1 samples in asset group "Plate asset group"
    Given a plate template exists
    Given a robot exists with barcode "444"

  Scenario: Cherrypicking a plate twice should display latest plate in report
    Given I have a cherrypicked plate with barcode "11111" and plate purpose "Infinium 670k"
    Given a study report is generated for study "Test study"
    Then the last report for "Test study" should be:
      | Well | Genotyping Chip | Genotyping Well | Genotyping Barcode |
      | A1   | Infinium 670k   | A1              | 11111              |

    Given I have a cherrypicked plate with barcode "22222" and plate purpose "ImmunoChip"
    Given a study report is generated for study "Test study"
    Then the last report for "Test study" should be:
      | Well | Genotyping Chip | Genotyping Well | Genotyping Barcode |
      | A1   | ImmunoChip      | A1              | 22222              |


   Scenario: A plate genotyped in SNP and recherrypicked in sequencescape
    Given I have a cherrypicked plate with barcode "11111" and plate purpose "Infinium 670k"
    And well "A1" on plate "11111" has a genotyping_done status of "DNAlab completed: 13"
    Given a study report is generated for study "Test study"
    Then the last report for "Test study" should be:
      | Well | Genotyping Chip | Genotyping Well | Genotyping Barcode |
      | A1   | Infinium 670k   | A1              | 11111              |

    Given I have a cherrypicked plate with barcode "22222" and plate purpose "ImmunoChip"
    Given a study report is generated for study "Test study"
    Then the last report for "Test study" should be:
      | Well | Genotyping Chip | Genotyping Well | Genotyping Barcode |
      | A1   | ImmunoChip      | A1              | 22222              |

