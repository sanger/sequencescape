Feature: Resetting batches and their requests across the various pipelines
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario Outline:
    Given user "John Smith" has a workflow "<workflow>"
    And I have a batch with 5 requests for the "<pipeline>" pipeline
    And the batch and all its requests are pending

    Given I am on the "<pipeline>" pipeline page
    When I follow "View pending batch 1"
    And I follow "Fail batch or items"
    And I check "Remove request" for 1 to 5
    And I select "Other" from "Select failure reason"
    And I press "Fail items/batch"
    Then I should see "removed."

    Then the 5 requests should be in the "<pipeline>" pipeline inbox

    @wip
    Scenarios: Library creation pipelines
      | pipeline                          | workflow            |
      | Illumina-C Library preparation    | Next-gen sequencing |
      | Illumina-B MX Library Preparation | Next-gen sequencing |
#     | Pulldown library preparation | Next-gen sequencing |    # Unused prototype?
#     | MX Library creation          | Next-gen sequencing |    # Unused

    @wip
    Scenarios: Sequencing pipelines
      | pipeline                                 | workflow            |
      | Cluster formation SE                     | Next-gen sequencing |
      | Cluster formation PE                     | Next-gen sequencing |
      | Cluster formation PE (no controls)       | Next-gen sequencing |
      | HiSeq Cluster formation PE (no controls) | Next-gen sequencing |
#     | Cluster formation SE HiSeq               | Next-gen sequencing |
#     | Cluster formation SE HiSeq (no controls) | Next-gen sequencing |

    Scenarios: Genotyping pipelines
      | pipeline               | workflow              |
      | DNA QC                 | Microarray genotyping |
      | Cherrypick             | Microarray genotyping |
      | Genotyping             | Microarray genotyping |

#     | Manual Quality Control | Microarray genotyping |  # Batch
