@pulldown @barcode-service @assign_tags @wip
Feature: Cherrypicking for Pulldown pipeline

  Background:
    Given I am a "administrator" user logged in as "user"
    Given I have a project called "Test project"

    Given I have an active study called "Test study"
    And I have an active study called "Study A"
    And the "96 Well Plate" barcode printer "xyz" exists

  Scenario: I select 2 pulldown plates for a batch, but the max is 1
    Given I have 2 pulldown plates
    Given I am on the show page for pipeline "Pulldown Multiplex Library Preparation"
    When I check "Select DN99999F for batch"
    And I check "Select DN88888N for batch"
    And I press the first "Submit"
    Then I should see "Too many request groups selected, maximum is 1"

  Scenario: View pulldown report for batch without assigning tags in batch
    Given I have a tag group called "UK10K tag group" with 8 tags
    Given I have a pulldown batch
    Given all library tube barcodes are set to know values
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
     | Plate    | Well | Study      | Pooled Tube    | Tag Group | Tag | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
     | DN99999F | A1   | Test study | 1              |           |     |                   | Sample_1234567_1 | 0.0             | 1.0                    |
     | DN99999F | B1   | Test study | 1              |           |     |                   | Sample_1234567_2 | 11.0            | 40.0                   |
     | DN99999F | C1   | Test study | 1              |           |     |                   | Sample_1234567_3 | 22.0            | 80.0                   |
     | DN99999F | D1   | Test study | 1              |           |     |                   | Sample_1234567_4 | 33.0            | 120.0                  |
     | DN99999F | E1   | Test study | 1              |           |     |                   | Sample_1234567_5 | 44.0            | 160.0                  |
     | DN99999F | F1   | Test study | 1              |           |     |                   | Sample_1234567_6 | 55.0            | 200.0                  |
     | DN99999F | G1   | Test study | 1              |           |     |                   | Sample_1234567_7 | 66.0            | 240.0                  |
     | DN99999F | H1   | Test study | 1              |           |     |                   | Sample_1234567_8 | 77.0            | 280.0                  |
     | DN99999F | A2   | Study A    | 2              |           |     |                   | Sample_222_1     | 0.0             | 1.0                    |
     | DN99999F | B2   | Study A    | 2              |           |     |                   | Sample_222_2     | 11.0            | 40.0                   |
     | DN99999F | C2   | Study A    | 2              |           |     |                   | Sample_222_3     | 22.0            | 80.0                   |
     | DN99999F | D2   | Study A    | 2              |           |     |                   | Sample_222_4     | 33.0            | 120.0                  |
     | DN99999F | E2   | Study A    | 2              |           |     |                   | Sample_222_5     | 44.0            | 160.0                  |
     | DN99999F | F2   | Study A    | 2              |           |     |                   | Sample_222_6     | 55.0            | 200.0                  |
     | DN99999F | G2   | Study A    | 2              |           |     |                   | Sample_222_7     | 66.0            | 240.0                  |
     | DN99999F | H2   | Study A    | 2              |           |     |                   | Sample_222_8     | 77.0            | 280.0                  |

  Scenario: Cherrypick and multiplex library prep for pulldown with 16 tags
    Given I have a tag group called "UK10K tag group" with 16 tags
    Given I have a pulldown batch
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    Then I should see "Assign Tags to Wells"
    And the default plates to wells table should look like:
    | 1     | 2      |
    | Tag 1 | Tag 9  |
    | Tag 2 | Tag 10 |
    | Tag 3 | Tag 11 |
    | Tag 4 | Tag 12 |
    | Tag 5 | Tag 13 |
    | Tag 6 | Tag 14 |
    | Tag 7 | Tag 15 |
    | Tag 8 | Tag 16 |
    | 1     | 2      |
    And I press "Next step"
    When I press "Release this batch"
    Then I should see "Batch released!"

  Scenario: Use 8 tags and rearrange manually in a valid order
    Given I have a tag group called "UK10K tag group" with 8 tags
    Given I have a pulldown batch
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    Then I should see "Assign Tags to Wells"
    And the default plates to wells table should look like:
    | 1     | 2     |
    | Tag 1 | Tag 1 |
    | Tag 2 | Tag 2 |
    | Tag 3 | Tag 3 |
    | Tag 4 | Tag 4 |
    | Tag 5 | Tag 5 |
    | Tag 6 | Tag 6 |
    | Tag 7 | Tag 7 |
    | Tag 8 | Tag 8 |
    | 1     | 2     |
    When I select "Tag 4" from "Well A1"
    And I select "Tag 3" from "Well B1"
    And I select "Tag 2" from "Well C1"
    And I select "Tag 1" from "Well D1"

    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    Then I should see "Batch released!"
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
    | Plate    | Well | Study      | Pooled Tube      | Tag Group       | Tag      | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
    | DN99999F | A1   | Test study | 1                | UK10K tag group | Tag 4    | TGACCA            | Sample_1234567_1 | 0.0             | 1.0                    |
    | DN99999F | B1   | Test study | 1                | UK10K tag group | Tag 3    | TTAGGC            | Sample_1234567_2 | 11.0            | 40.0                   |
    | DN99999F | C1   | Test study | 1                | UK10K tag group | Tag 2    | CGATGT            | Sample_1234567_3 | 22.0            | 80.0                   |
    | DN99999F | D1   | Test study | 1                | UK10K tag group | Tag 1    | ATCACG            | Sample_1234567_4 | 33.0            | 120.0                  |
    | DN99999F | E1   | Test study | 1                | UK10K tag group | Tag 5    | ATCACG            | Sample_1234567_5 | 44.0            | 160.0                  |
    | DN99999F | F1   | Test study | 1                | UK10K tag group | Tag 6    | CGATGT            | Sample_1234567_6 | 55.0            | 200.0                  |
    | DN99999F | G1   | Test study | 1                | UK10K tag group | Tag 7    | TTAGGC            | Sample_1234567_7 | 66.0            | 240.0                  |
    | DN99999F | H1   | Test study | 1                | UK10K tag group | Tag 8    | TGACCA            | Sample_1234567_8 | 77.0            | 280.0                  |
    | DN99999F | A2   | Study A    | 2                | UK10K tag group | Tag 1    | ATCACG            | Sample_222_1     | 0.0             | 1.0                    |
    | DN99999F | B2   | Study A    | 2                | UK10K tag group | Tag 2    | CGATGT            | Sample_222_2     | 11.0            | 40.0                   |
    | DN99999F | C2   | Study A    | 2                | UK10K tag group | Tag 3    | TTAGGC            | Sample_222_3     | 22.0            | 80.0                   |
    | DN99999F | D2   | Study A    | 2                | UK10K tag group | Tag 4    | TGACCA            | Sample_222_4     | 33.0            | 120.0                  |
    | DN99999F | E2   | Study A    | 2                | UK10K tag group | Tag 5    | ATCACG            | Sample_222_5     | 44.0            | 160.0                  |
    | DN99999F | F2   | Study A    | 2                | UK10K tag group | Tag 6    | CGATGT            | Sample_222_6     | 55.0            | 200.0                  |
    | DN99999F | G2   | Study A    | 2                | UK10K tag group | Tag 7    | TTAGGC            | Sample_222_7     | 66.0            | 240.0                  |
    | DN99999F | H2   | Study A    | 2                | UK10K tag group | Tag 8    | TGACCA            | Sample_222_8     | 77.0            | 280.0                  |

  Scenario: Use 8 tags and rearrange manually in an invalid order
    Given I have a tag group called "UK10K tag group" with 8 tags
    Given I have a pulldown batch

    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    Then I should see "Assign Tags to Wells"
    And the default plates to wells table should look like:
    | 1     | 2     |
    | Tag 1 | Tag 1 |
    | Tag 2 | Tag 2 |
    | Tag 3 | Tag 3 |
    | Tag 4 | Tag 4 |
    | Tag 5 | Tag 5 |
    | Tag 6 | Tag 6 |
    | Tag 7 | Tag 7 |
    | Tag 8 | Tag 8 |
    | 1     | 2     |
    When I select "Tag 1" from "Well B1"
    And I select "Tag 1" from "Well C1"

    And I press "Next step"
    Then I should see "Duplicate tags in a single pooled tube"
    Given I am on the last batch show page
    Given all library tube barcodes are set to know values
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
    | Plate    | Well | Study      |  Pooled Tube    | Tag Group | Tag | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
    | DN99999F | A1   | Test study | 1               |           |     |                   | Sample_1234567_1 | 0.0             | 1.0                    |
    | DN99999F | B1   | Test study | 1               |           |     |                   | Sample_1234567_2 | 11.0            | 40.0                   |
    | DN99999F | C1   | Test study | 1               |           |     |                   | Sample_1234567_3 | 22.0            | 80.0                   |
    | DN99999F | D1   | Test study | 1               |           |     |                   | Sample_1234567_4 | 33.0            | 120.0                  |
    | DN99999F | E1   | Test study | 1               |           |     |                   | Sample_1234567_5 | 44.0            | 160.0                  |
    | DN99999F | F1   | Test study | 1               |           |     |                   | Sample_1234567_6 | 55.0            | 200.0                  |
    | DN99999F | G1   | Test study | 1               |           |     |                   | Sample_1234567_7 | 66.0            | 240.0                  |
    | DN99999F | H1   | Test study | 1               |           |     |                   | Sample_1234567_8 | 77.0            | 280.0                  |
    | DN99999F | A2   | Study A    | 2               |           |     |                   | Sample_222_1     | 0.0             | 1.0                    |
    | DN99999F | B2   | Study A    | 2               |           |     |                   | Sample_222_2     | 11.0            | 40.0                   |
    | DN99999F | C2   | Study A    | 2               |           |     |                   | Sample_222_3     | 22.0            | 80.0                   |
    | DN99999F | D2   | Study A    | 2               |           |     |                   | Sample_222_4     | 33.0            | 120.0                  |
    | DN99999F | E2   | Study A    | 2               |           |     |                   | Sample_222_5     | 44.0            | 160.0                  |
    | DN99999F | F2   | Study A    | 2               |           |     |                   | Sample_222_6     | 55.0            | 200.0                  |
    | DN99999F | G2   | Study A    | 2               |           |     |                   | Sample_222_7     | 66.0            | 240.0                  |
    | DN99999F | H2   | Study A    | 2               |           |     |                   | Sample_222_8     | 77.0            | 280.0                  |


  Scenario: Apply 8 tags and progress to hiseq sequencing
    Given I have a tag group called "UK10K tag group" with 8 tags
    Given I have a pulldown batch
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    When I set Pulldown Multiplexed Library "3980000001795" to be in freezer "Cluster formation freezer"
    And I set Pulldown Multiplexed Library "3980000002808" to be in freezer "Cluster formation freezer"
    Given I am on the show page for pipeline "HiSeq Cluster formation PE (no controls)"
    When I check "Select PulldownMultiplexedLibraryTube 1 for batch"
    And I check "Select PulldownMultiplexedLibraryTube 2 for batch"
    And I press the first "Submit"
    And I follow "Specify Dilution Volume"
    And I press "Next step"
    And I press "Next step"
    And I press "Next step"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    Then I should see "Batch released!"

  Scenario: Change your mind about tag assignment before releasing the batch
    Given I have a tag group called "UK10K tag group" with 8 tags
    Given I have a pulldown batch
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    And I press "Next step"
    Given all library tube barcodes are set to know values
    Given I am on the last batch show page
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
      | Plate    | Well | Study      | Pooled Tube     |   Tag Group      | Tag      | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
      | DN99999F | A1   | Test study | 1               |  UK10K tag group | Tag 1    | ATCACG            | Sample_1234567_1 | 0.0             | 1.0                    |
      | DN99999F | B1   | Test study | 1               |  UK10K tag group | Tag 2    | CGATGT            | Sample_1234567_2 | 11.0            | 40.0                   |
      | DN99999F | C1   | Test study | 1               |  UK10K tag group | Tag 3    | TTAGGC            | Sample_1234567_3 | 22.0            | 80.0                   |
      | DN99999F | D1   | Test study | 1               |  UK10K tag group | Tag 4    | TGACCA            | Sample_1234567_4 | 33.0            | 120.0                  |
      | DN99999F | E1   | Test study | 1               |  UK10K tag group | Tag 5    | ATCACG            | Sample_1234567_5 | 44.0            | 160.0                  |
      | DN99999F | F1   | Test study | 1               |  UK10K tag group | Tag 6    | CGATGT            | Sample_1234567_6 | 55.0            | 200.0                  |
      | DN99999F | G1   | Test study | 1               |  UK10K tag group | Tag 7    | TTAGGC            | Sample_1234567_7 | 66.0            | 240.0                  |
      | DN99999F | H1   | Test study | 1               |  UK10K tag group | Tag 8    | TGACCA            | Sample_1234567_8 | 77.0            | 280.0                  |
      | DN99999F | A2   | Study A    | 2               |  UK10K tag group | Tag 1    | ATCACG            | Sample_222_1     | 0.0             | 1.0                    |
      | DN99999F | B2   | Study A    | 2               |  UK10K tag group | Tag 2    | CGATGT            | Sample_222_2     | 11.0            | 40.0                   |
      | DN99999F | C2   | Study A    | 2               |  UK10K tag group | Tag 3    | TTAGGC            | Sample_222_3     | 22.0            | 80.0                   |
      | DN99999F | D2   | Study A    | 2               |  UK10K tag group | Tag 4    | TGACCA            | Sample_222_4     | 33.0            | 120.0                  |
      | DN99999F | E2   | Study A    | 2               |  UK10K tag group | Tag 5    | ATCACG            | Sample_222_5     | 44.0            | 160.0                  |
      | DN99999F | F2   | Study A    | 2               |  UK10K tag group | Tag 6    | CGATGT            | Sample_222_6     | 55.0            | 200.0                  |
      | DN99999F | G2   | Study A    | 2               |  UK10K tag group | Tag 7    | TTAGGC            | Sample_222_7     | 66.0            | 240.0                  |
      | DN99999F | H2   | Study A    | 2               |  UK10K tag group | Tag 8    | TGACCA            | Sample_222_8     | 77.0            | 280.0                  |

    Given I am on the last batch show page
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    When I select "Tag 4" from "Well A1"
    And I select "Tag 3" from "Well B1"
    And I select "Tag 2" from "Well C1"
    And I select "Tag 1" from "Well D1"
    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    Then I should see "Batch released!"
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
      | Plate    | Well | Study      | Pooled Tube      | Tag Group       | Tag      | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
      | DN99999F | A1   | Test study | 1                | UK10K tag group | Tag 4    | TGACCA            | Sample_1234567_1 | 0.0             | 1.0                    |
      | DN99999F | B1   | Test study | 1                | UK10K tag group | Tag 3    | TTAGGC            | Sample_1234567_2 | 11.0            | 40.0                   |
      | DN99999F | C1   | Test study | 1                | UK10K tag group | Tag 2    | CGATGT            | Sample_1234567_3 | 22.0            | 80.0                   |
      | DN99999F | D1   | Test study | 1                | UK10K tag group | Tag 1    | ATCACG            | Sample_1234567_4 | 33.0            | 120.0                  |
      | DN99999F | E1   | Test study | 1                | UK10K tag group | Tag 5    | ATCACG            | Sample_1234567_5 | 44.0            | 160.0                  |
      | DN99999F | F1   | Test study | 1                | UK10K tag group | Tag 6    | CGATGT            | Sample_1234567_6 | 55.0            | 200.0                  |
      | DN99999F | G1   | Test study | 1                | UK10K tag group | Tag 7    | TTAGGC            | Sample_1234567_7 | 66.0            | 240.0                  |
      | DN99999F | H1   | Test study | 1                | UK10K tag group | Tag 8    | TGACCA            | Sample_1234567_8 | 77.0            | 280.0                  |
      | DN99999F | A2   | Study A    | 2                | UK10K tag group | Tag 1    | ATCACG            | Sample_222_1     | 0.0             | 1.0                    |
      | DN99999F | B2   | Study A    | 2                | UK10K tag group | Tag 2    | CGATGT            | Sample_222_2     | 11.0            | 40.0                   |
      | DN99999F | C2   | Study A    | 2                | UK10K tag group | Tag 3    | TTAGGC            | Sample_222_3     | 22.0            | 80.0                   |
      | DN99999F | D2   | Study A    | 2                | UK10K tag group | Tag 4    | TGACCA            | Sample_222_4     | 33.0            | 120.0                  |
      | DN99999F | E2   | Study A    | 2                | UK10K tag group | Tag 5    | ATCACG            | Sample_222_5     | 44.0            | 160.0                  |
      | DN99999F | F2   | Study A    | 2                | UK10K tag group | Tag 6    | CGATGT            | Sample_222_6     | 55.0            | 200.0                  |
      | DN99999F | G2   | Study A    | 2                | UK10K tag group | Tag 7    | TTAGGC            | Sample_222_7     | 66.0            | 240.0                  |
      | DN99999F | H2   | Study A    | 2                | UK10K tag group | Tag 8    | TGACCA            | Sample_222_8     | 77.0            | 280.0                  |

  Scenario: Release batch then change your mind about tag assignment
    Given I have a tag group called "UK10K tag group" with 8 tags
    Given I have a pulldown batch
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    Given I am on the last batch show page
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
      | Plate    | Well | Study      | Pooled Tube     |   Tag Group      | Tag      | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
      | DN99999F | A1   | Test study | 1               |  UK10K tag group | Tag 1    | ATCACG            | Sample_1234567_1 | 0.0             | 1.0                    |
      | DN99999F | B1   | Test study | 1               |  UK10K tag group | Tag 2    | CGATGT            | Sample_1234567_2 | 11.0            | 40.0                   |
      | DN99999F | C1   | Test study | 1               |  UK10K tag group | Tag 3    | TTAGGC            | Sample_1234567_3 | 22.0            | 80.0                   |
      | DN99999F | D1   | Test study | 1               |  UK10K tag group | Tag 4    | TGACCA            | Sample_1234567_4 | 33.0            | 120.0                  |
      | DN99999F | E1   | Test study | 1               |  UK10K tag group | Tag 5    | ATCACG            | Sample_1234567_5 | 44.0            | 160.0                  |
      | DN99999F | F1   | Test study | 1               |  UK10K tag group | Tag 6    | CGATGT            | Sample_1234567_6 | 55.0            | 200.0                  |
      | DN99999F | G1   | Test study | 1               |  UK10K tag group | Tag 7    | TTAGGC            | Sample_1234567_7 | 66.0            | 240.0                  |
      | DN99999F | H1   | Test study | 1               |  UK10K tag group | Tag 8    | TGACCA            | Sample_1234567_8 | 77.0            | 280.0                  |
      | DN99999F | A2   | Study A    | 2               |  UK10K tag group | Tag 1    | ATCACG            | Sample_222_1     | 0.0             | 1.0                    |
      | DN99999F | B2   | Study A    | 2               |  UK10K tag group | Tag 2    | CGATGT            | Sample_222_2     | 11.0            | 40.0                   |
      | DN99999F | C2   | Study A    | 2               |  UK10K tag group | Tag 3    | TTAGGC            | Sample_222_3     | 22.0            | 80.0                   |
      | DN99999F | D2   | Study A    | 2               |  UK10K tag group | Tag 4    | TGACCA            | Sample_222_4     | 33.0            | 120.0                  |
      | DN99999F | E2   | Study A    | 2               |  UK10K tag group | Tag 5    | ATCACG            | Sample_222_5     | 44.0            | 160.0                  |
      | DN99999F | F2   | Study A    | 2               |  UK10K tag group | Tag 6    | CGATGT            | Sample_222_6     | 55.0            | 200.0                  |
      | DN99999F | G2   | Study A    | 2               |  UK10K tag group | Tag 7    | TTAGGC            | Sample_222_7     | 66.0            | 240.0                  |
      | DN99999F | H2   | Study A    | 2               |  UK10K tag group | Tag 8    | TGACCA            | Sample_222_8     | 77.0            | 280.0                  |
    Given I am on the last batch show page
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    When I select "Tag 4" from "Well A1"
    And I select "Tag 3" from "Well B1"
    And I select "Tag 2" from "Well C1"
    And I select "Tag 1" from "Well D1"
    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    Then I should see "Batch released!"
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
      | Plate    | Well | Study      | Pooled Tube      | Tag Group       | Tag      | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
      | DN99999F | A1   | Test study | 1                | UK10K tag group | Tag 4    | TGACCA            | Sample_1234567_1 | 0.0             | 1.0                    |
      | DN99999F | B1   | Test study | 1                | UK10K tag group | Tag 3    | TTAGGC            | Sample_1234567_2 | 11.0            | 40.0                   |
      | DN99999F | C1   | Test study | 1                | UK10K tag group | Tag 2    | CGATGT            | Sample_1234567_3 | 22.0            | 80.0                   |
      | DN99999F | D1   | Test study | 1                | UK10K tag group | Tag 1    | ATCACG            | Sample_1234567_4 | 33.0            | 120.0                  |
      | DN99999F | E1   | Test study | 1                | UK10K tag group | Tag 5    | ATCACG            | Sample_1234567_5 | 44.0            | 160.0                  |
      | DN99999F | F1   | Test study | 1                | UK10K tag group | Tag 6    | CGATGT            | Sample_1234567_6 | 55.0            | 200.0                  |
      | DN99999F | G1   | Test study | 1                | UK10K tag group | Tag 7    | TTAGGC            | Sample_1234567_7 | 66.0            | 240.0                  |
      | DN99999F | H1   | Test study | 1                | UK10K tag group | Tag 8    | TGACCA            | Sample_1234567_8 | 77.0            | 280.0                  |
      | DN99999F | A2   | Study A    | 2                | UK10K tag group | Tag 1    | ATCACG            | Sample_222_1     | 0.0             | 1.0                    |
      | DN99999F | B2   | Study A    | 2                | UK10K tag group | Tag 2    | CGATGT            | Sample_222_2     | 11.0            | 40.0                   |
      | DN99999F | C2   | Study A    | 2                | UK10K tag group | Tag 3    | TTAGGC            | Sample_222_3     | 22.0            | 80.0                   |
      | DN99999F | D2   | Study A    | 2                | UK10K tag group | Tag 4    | TGACCA            | Sample_222_4     | 33.0            | 120.0                  |
      | DN99999F | E2   | Study A    | 2                | UK10K tag group | Tag 5    | ATCACG            | Sample_222_5     | 44.0            | 160.0                  |
      | DN99999F | F2   | Study A    | 2                | UK10K tag group | Tag 6    | CGATGT            | Sample_222_6     | 55.0            | 200.0                  |
      | DN99999F | G2   | Study A    | 2                | UK10K tag group | Tag 7    | TTAGGC            | Sample_222_7     | 66.0            | 240.0                  |
      | DN99999F | H2   | Study A    | 2                | UK10K tag group | Tag 8    | TGACCA            | Sample_222_8     | 77.0            | 280.0                  |

  Scenario: Different sized submissions
    Given I have a tag group called "UK10K tag group" with 4 tags
    And I have an active study called "Study B"
    And I have an active study called "Study C"
    Given plate "1234567" with 2 samples in study "Test study" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission
    Given plate "222" with 1 samples in study "Study A" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission
    Given plate "333" with 3 samples in study "Study B" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission
    Given plate "444" with 4 samples in study "Study C" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission
    Given plate "1234567" has nonzero concentration results
    Given plate "222" has nonzero concentration results
    Given plate "333" has nonzero concentration results
    Given plate "444" has nonzero concentration results
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN1234567T for batch"
    And I check "Select DN222J for batch"
    And I check "Select DN333P for batch"
    And I check "Select DN444V for batch"
    And I press the first "Submit"
    Given a plate barcode webservice is available and returns "99999"
    When I follow "Select Plate Template"
    When I fill in "Volume Required" with "13"
    And I fill in "Concentration Required" with "50"
    And I select "Pulldown Aliquot" from "Plate Purpose"
    And I press "Next step"
    When I press "Release this batch"
    When I set Plate "1220099999705" to be in freezer "Pulldown freezer"
    Given I am on the show page for pipeline "Pulldown Multiplex Library Preparation"
    When I check "Select DN99999F for batch"
    And I press the first "Submit"
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    Given I am on the last batch show page
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
      | Plate    | Well | Study      | Pooled Tube | Tag Group       | Tag   | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
      | DN99999F | A1   | Test study | 1           | UK10K tag group | Tag 1 | ATCACG            | Sample_1234567_1 | 0.0             | 1.0                    |
      | DN99999F | B1   | Test study | 1           | UK10K tag group | Tag 2 | CGATGT            | Sample_1234567_2 | 11.0            | 40.0                   |
      | DN99999F | C1   | Study C    | 4           | UK10K tag group | Tag 3 | TTAGGC            | Sample_444_1     | 0.0             | 1.0                    |
      | DN99999F | D1   | Study C    | 4           | UK10K tag group | Tag 4 | TGACCA            | Sample_444_2     | 11.0            | 40.0                   |
      | DN99999F | E1   | Study C    | 4           | UK10K tag group | Tag 1 | ATCACG            | Sample_444_3     | 22.0            | 80.0                   |
      | DN99999F | F1   | Study C    | 4           | UK10K tag group | Tag 2 | CGATGT            | Sample_444_4     | 33.0            | 120.0                  |
      | DN99999F | G1   | Study B    | 3           | UK10K tag group | Tag 3 | TTAGGC            | Sample_333_1     | 0.0             | 1.0                    |
      | DN99999F | H1   | Study B    | 3           | UK10K tag group | Tag 4 | TGACCA            | Sample_333_2     | 11.0            | 40.0                   |
      | DN99999F | A2   | Study B    | 3           | UK10K tag group | Tag 1 | ATCACG            | Sample_333_3     | 22.0            | 80.0                   |
      | DN99999F | B2   | Study A    | 2           | UK10K tag group | Tag 2 | CGATGT            | Sample_222_1     | 0.0             | 1.0                    |

  Scenario: Different sized submissions and the tag group is too small
    Given I have a tag group called "UK10K tag group" with 2 tags
    Given plate "1234567" with 3 samples in study "Test study" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission
    Given plate "222" with 1 samples in study "Study A" has a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" submission
    Given plate "1234567" has nonzero concentration results
    Given plate "222" has nonzero concentration results
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN1234567T for batch"
    And I check "Select DN222J for batch"
    And I press the first "Submit"
    Given a plate barcode webservice is available and returns "99999"
    When I follow "Select Plate Template"
    When I fill in "Volume Required" with "13"
    And I fill in "Concentration Required" with "50"
    And I select "Pulldown Aliquot" from "Plate Purpose"
    And I press "Next step"
    When I press "Release this batch"
    When I set Plate "1220099999705" to be in freezer "Pulldown freezer"
    Given I am on the show page for pipeline "Pulldown Multiplex Library Preparation"
    When I check "Select DN99999F for batch"
    And I press the first "Submit"
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    Then I should see "Duplicate tags will be assigned to a pooled tube, select a different tag group"

  Scenario: Paired ended sequencing after pulldown multiplexing
    Given I have a tag group called "UK10K tag group" with 4 tags
    Given I have a plate "1234567" in study "Test study" with 3 samples in asset group "Plate asset group 1234567"
    Given plate "1234567" has nonzero concentration results
    Given plate "1234567" has measured volume results
    Given I am on the show page for study "Test study"

    Given I have a "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - Paired end sequencing" submission with the following setup:
      | Project | Test project |
      | Study | Test study |
      | Asset Group | Plate asset group 1234567 |
      | Fragment size required from | 300|
      | Fragment size required to | 400|
      | Read length  | 108 |

    #And I select "108" from "Read length"
    #When I follow "Create Submission"
    #When I select "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - Paired end sequencing" from "Template"
    #And I press "Next"
    #When I select "Test study" from "Select a study"
    #When I select "Test project" from "Select a financial project"
    #And I select "Plate asset group 1234567" from "Select a group to submit"
    #And I fill in "Fragment size required (from)" with "300"
    #And I fill in "Fragment size required (to)" with "400"
    #And I select "108" from "Read length"
    #And I create the order and submit the submission
    Given 1 pending delayed jobs are processed
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN1234567T for batch"
    And I press the first "Submit"
    Given a plate barcode webservice is available and returns "99999"
    When I follow "Select Plate Template"
    When I fill in "Volume Required" with "13"
    And I fill in "Concentration Required" with "50"
    And I select "Pulldown Aliquot" from "Plate Purpose"
    And I press "Next step"
    When I press "Release this batch"
    When I set Plate "1220099999705" to be in freezer "Pulldown freezer"
    Given I am on the show page for pipeline "Pulldown Multiplex Library Preparation"
    When I check "Select DN99999F for batch"
    And I press the first "Submit"
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    When I set Pulldown Multiplexed Library "3980000001795" to be in freezer "Cluster formation freezer"
    Given I am on the show page for pipeline "Cluster formation PE"
    When I check "Select PulldownMultiplexedLibraryTube 1 for batch"
    And I select "Create Batch" from the first "action_on_requests"
    And I press the first "Submit"
    And I follow "Specify Dilution Volume"
    And I press "Next step"
    And I press "Next step"
    And I press "Next step"
    And I press "Next step"
    And I press "Next step"
    When I press "Release this batch"
    Then I should see "Batch released!"


  Scenario: Worksheet with 8 tags
    Given I have a tag group called "UK10K tag group" with 8 tags
    Given I have a pulldown batch
    When I follow "Tag Groups"
    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    Then I should see "Assign Tags to Wells"
    And the default plates to wells table should look like:
    | 1     | 2     |
    | Tag 1 | Tag 1 |
    | Tag 2 | Tag 2 |
    | Tag 3 | Tag 3 |
    | Tag 4 | Tag 4 |
    | Tag 5 | Tag 5 |
    | Tag 6 | Tag 6 |
    | Tag 7 | Tag 7 |
    | Tag 8 | Tag 8 |
    | 1     | 2     |

    And I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    Then I should see "Batch released!"
    When I follow "Print worksheet"
    Then the worksheet for the last batch should be:
     |  Pooled Tube | Plate    | Well | Tag      |  Sample           |
     |  1           | DN99999F | A1   | Tag 1    |  Sample_1234567_1 |
     |  1           | DN99999F | B1   | Tag 2    |  Sample_1234567_2 |
     |  1           | DN99999F | C1   | Tag 3    |  Sample_1234567_3 |
     |  1           | DN99999F | D1   | Tag 4    |  Sample_1234567_4 |
     |  1           | DN99999F | E1   | Tag 5    |  Sample_1234567_5 |
     |  1           | DN99999F | F1   | Tag 6    |  Sample_1234567_6 |
     |  1           | DN99999F | G1   | Tag 7    |  Sample_1234567_7 |
     |  1           | DN99999F | H1   | Tag 8    |  Sample_1234567_8 |
     |  2           | DN99999F | A2   | Tag 1    |  Sample_222_1     |
     |  2           | DN99999F | B2   | Tag 2    |  Sample_222_2     |
     |  2           | DN99999F | C2   | Tag 3    |  Sample_222_3     |
     |  2           | DN99999F | D2   | Tag 4    |  Sample_222_4     |
     |  2           | DN99999F | E2   | Tag 5    |  Sample_222_5     |
     |  2           | DN99999F | F2   | Tag 6    |  Sample_222_6     |
     |  2           | DN99999F | G2   | Tag 7    |  Sample_222_7     |
     |  2           | DN99999F | H2   | Tag 8    |  Sample_222_8     |


