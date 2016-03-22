Feature: Resetting batches and their requests across the various pipelines
  Background:
    Given I am an "administrator" user logged in as "John Smith"

  Scenario Outline:
    Given user "John Smith" has a workflow "<workflow>"
    And I have a batch with 5 requests for the "<pipeline>" pipeline
    And the batch and all its requests are pending

    Given I am on the "<pipeline>" pipeline page
    When I follow "View pending batch 1"
    Then I should not see "Fail batch or items"
    When I follow "<link>"
    And I follow "Fail batch"
    And I check "Remove request" for 1 to 5
    And I select "Other" from "Select failure reason"
    And I press "Fail selected requests"
    Then I should see "removed."

    Then the 5 requests should be in the "<pipeline>" pipeline inbox

    @wip
    Scenarios: Library creation pipelines
      | pipeline                          | workflow            | link       |
      | Illumina-C Library preparation    | Next-gen sequencing | Tag Groups |
      | Illumina-B MX Library Preparation | Next-gen sequencing | Tag Groups |

    @wip
    Scenarios: Sequencing pipelines
      | pipeline                                 | workflow            | link                    |
      | Cluster formation SE                     | Next-gen sequencing | Specify Dilution Volume |
      | Cluster formation PE                     | Next-gen sequencing | Specify Dilution Volume |
      | Cluster formation PE (no controls)       | Next-gen sequencing | Specify Dilution Volume |
      | HiSeq Cluster formation PE (no controls) | Next-gen sequencing | Specify Dilution Volume |

    Scenarios: Genotyping pipelines
      | pipeline               | workflow              | link                  |
      | DNA QC                 | Microarray genotyping | QC result             |
      | Cherrypick             | Microarray genotyping | Select Plate Template |
      | Genotyping             | Microarray genotyping | Generate Manifests    |
