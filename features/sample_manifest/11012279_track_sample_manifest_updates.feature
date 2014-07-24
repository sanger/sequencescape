@sample @manifest @barcode-service
Feature: Track when a sample and its plate has been updated by a manifest

  Background:
    Given I freeze time at "Mon Jul 12 10:23:58 UTC 2010"
    Given I am an "External" user logged in as "john"
    And the "96 Well Plate" barcode printer "xyz" exists
    And the plate barcode webservice returns "1234567"
    Given a supplier called "Test supplier name" exists
    And I have an active study called "Test study"
    Given the study "Test study" has a abbreviation
    And user "john" is a "manager" of study "Test study"
    And the study have a workflow
    Given I am visiting study "Test study" homepage
    Then I should see "Test study"
    When I follow "Sample Manifests"
    Then I should see "Create manifest for plates"


  @sample_manifest_events
  Scenario: Some samples get updated by a manifest and events get created
    Given a manifest has been created for "Test study"

    Given I am on the event history page for sample with sanger_sample_id "sample_1"
    Then the events table should be:
      | Message                    | Content    | Created by | Created at           |
      | Created by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |

    Given I am on the event history page for sample with sanger_sample_id "sample_7"
    Then the events table should be:
      | Message                    | Content    | Created by | Created at           |
      | Created by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |

    Given I am on the sample db homepage
    When I follow "View all manifests"
      And I fill in "File to upload" with "test/data/test_blank_wells.csv"
      And I press "Upload manifest"
    Given 1 pending delayed jobs are processed

    Given I am on the event history page for sample with sanger_sample_id "sample_1"
    Then the events table should be:
      | Message                    | Content    | Created by | Created at           |
      | Created by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |
      | Updated by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |

    Given I am on the event history page for sample with sanger_sample_id "sample_7"
    Then the events table should be:
      | Message                    | Content    | Created by | Created at           |
      | Created by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |

    # A different user logs in and updates the manifest
    Given I am an "External" user logged in as "jane"
    Given I am on the sample db homepage
    When I follow "View all manifests"
      And I fill in "File to upload" with "test/data/test_blank_wells_with_no_blanks.csv"
      And I check "Override previously uploaded samples"
      And I press "Upload manifest"
    Given 1 pending delayed jobs are processed

   Given I am on the event history page for sample with sanger_sample_id "sample_1"
   Then the events table should be:
     | Message                    | Content    | Created by | Created at           |
     | Created by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |
     | Updated by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |
     | Updated by Sample Manifest | 2010-07-12 | jane       | Monday 12 July, 2010 |

   Given I am on the event history page for sample with sanger_sample_id "sample_7"
   Then the events table should be:
     | Message                    | Content    | Created by | Created at           |
     | Created by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |
     | Updated by Sample Manifest | 2010-07-12 | jane       | Monday 12 July, 2010 |

   Given I am on the events page for asset with barcode "1221234567841"
   Then the events table should be:
     | Message                    | Content    | Created by | Created at           |
     | Created by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |
     | Updated by Sample Manifest | 2010-07-12 | john       | Monday 12 July, 2010 |
     | Updated by Sample Manifest | 2010-07-12 | jane       | Monday 12 July, 2010 |

