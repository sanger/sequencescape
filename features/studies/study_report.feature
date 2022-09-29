@study_report
Feature: create a report on the current state of a study going through QC

  Background:
    Given I am a "manager" user logged in as "user"
    And I am on the homepage
    Given a study named "Study A" exists
    And a study named "Study B" exists
    And I travel through time to "Mon Jul 12 10:23:58 UTC 2010"

  Scenario: List reports for a given study
    Given I am visiting study "Study A" homepage
    And there is 1 pending report for study "Study A"
    And there is 1 completed report for study "Study A"
    When I follow "Study QC Reports"
    Then I should see "QC Reports for Study A"
     Then I should see qc reports table:
      | Study   | Created on | Created by | Download   | Rerun |
      | Study A | 2010-07-12 | user       | Download   | Rerun |
      | Study A | 2010-07-12 | user       | Processing |       |

  Scenario: List reports for a given user
    Given there is 1 pending report for study "Study A"
    And there is 1 completed report for study "Study B"
    Given I am on the profile page for "user"
    Then I should see "Qc Reports"
    When I follow "Qc Reports"
    Then I should see "Qc Reports for user"
     Then I should see qc reports table:
      | Study   | Created on | Created by | Download   | Rerun |
      | Study B | 2010-07-12 | user       | Download   | Rerun |
      | Study A | 2010-07-12 | user       | Processing |       |


  Scenario: Filter reports by a given study
    Given there is 1 pending report for study "Study A"
    And there is 1 completed report for study "Study B"
    And I am on the Qc reports homepage
     Then I should see qc reports table:
      | Study   | Created on | Created by | Download   | Rerun |
      | Study B | 2010-07-12 | user       | Download   | Rerun |
      | Study A | 2010-07-12 | user       | Processing |       |
    When I follow "Study A"
    Then I should see qc reports table:
      | Study   | Created on | Created by | Download   | Rerun |
      | Study A | 2010-07-12 | user       | Processing |       |

  Scenario: List all reports
    Given there is 1 pending report for study "Study A"
    And there is 1 completed report for study "Study B"
    And I am on the Qc reports homepage
    Then I should see qc reports table:
      | Study   | Created on | Created by | Download   | Rerun |
      | Study B | 2010-07-12 | user       | Download   | Rerun |
      | Study A | 2010-07-12 | user       | Processing |       |

  Scenario: Generate a new report from the Qc reports homepage
    Given study "Study B" has a plate "SQPD-1234567"
    Given I am on the Qc reports homepage
    Then I should see "New report for"
    When I select "Study B" from "Study"
    And I press "Submit"
    Then I should see "Report being generated"
     Then I should see qc reports table:
      | Study   | Created on | Created by | Download   | Rerun |
      | Study B | 2010-07-12 | user       | Processing |       |
    Then the last delayed job should have a priority of 100
    Given 1 pending delayed jobs are processed
    And I am on the Qc reports homepage
    Then I should see qc reports table:
      | Study   | Created on | Created by | Download | Rerun |
      | Study B | 2010-07-12 | user       | Download | Rerun |
    Then I follow "Download report for Study B"
    Then I should see the report for "Study B":
    | Study   |  Plate   |  Concentration | Sequenome Count | Sequenome Gender | Pico | Gel  | Supplier Sample Name | Well | Total Micrograms | Initial Volume |
    | Study B |  SQPD-1234567 |  1.0           | 29/30           | FFFF             | Pass | Pass | Sample_SQPD-1234567_1     | A1   | 0.5              | 500.0          |
    | Study B |  SQPD-1234567 |  1.0           | 29/30           | FFFF             | Pass | Pass | Sample_SQPD-1234567_2     | A2   | 0.5              | 500.0          |
    | Study B |  SQPD-1234567 |  1.0           | 29/30           | FFFF             | Pass | Pass | Sample_SQPD-1234567_3     | A3   | 0.5              | 500.0          |

  @delayed_job @admin
  Scenario: Create a study report and check it appears in on the list
    Given I am a "administrator" user logged in as "admin"
    Given study "Study B" has a plate "SQPD-1234567"
    Given I am on the Qc reports homepage
    Then I should see "New report for"
    When I select "Study B" from "Study"
    And I press "Submit"
    Then I should see "Report being generated"
    When I am on the delayed jobs admin page
    Then I should see "generate study report"
    Given all pending delayed jobs are processed
    When I am on the delayed jobs admin page # refreshing
    Then I should not see "generate study report"

  Scenario: The wells have child sample tubes
    Given study "Study B" has a plate "SQPD-1234567"
    Given each well in "Study B" has a child sample tube
    Given a study report is generated for study "Study B"
    Then the last report for "Study B" should be:
      | Study   | Plate   | Well |
      | Study B | SQPD-1234567 | A1   |
      | Study B | SQPD-1234567 | A2   |
      | Study B | SQPD-1234567 | A3   |

  @manifest
  Scenario: Samples have been created by have no manifest uploaded
    Given study "Study B" has a plate "SQPD-1234567"
    Given a study report is generated for study "Study B"
    Then the last report for "Study B" should be:
      | Study   | Plate   | Well | Status            |
      | Study B | SQPD-1234567 | A1   | Awaiting manifest |
      | Study B | SQPD-1234567 | A2   | Awaiting manifest |
      | Study B | SQPD-1234567 | A3   | Awaiting manifest |

  @manifest
  Scenario: Samples have been created by have no manifest uploaded
    Given study "Study B" has a plate "SQPD-1234567"
    Given each sample was updated by a sample manifest
    Given a study report is generated for study "Study B"
    Then the last report for "Study B" should be:
      | Study   | Plate   | Well | Status              |
      | Study B | SQPD-1234567 | A1   | Updated by manifest |
      | Study B | SQPD-1234567 | A2   | Updated by manifest |
      | Study B | SQPD-1234567 | A3   | Updated by manifest |

