@volume @volume_check
Feature: Upload volume results from the volume checker robot

  Background:
    Given I am a "manager" user logged in as "user"
    And a study named "Study B" exists

  Scenario: Update measured volume results on one plate
    Given I have a project called "Test project"

    Given study "Study B" has a plate "1234567" to be volume checked
    Given all plate volume check files are processed
    Given a study report is generated for study "Study B"
     And I am on the Qc reports homepage
    Then I follow "Download report for Study B"
    Then I should see the report for "Study B":
      | Plate   | Well |Measured Volume |
      | 1234567 | A1   |55.3281         |
      | 1234567 | A2   |25.296          |
      | 1234567 | A3   |0.1074          |
      | 1234567 | A4   |0.0547          |
      | 1234567 | A5   |0.0             |
      | 1234567 | A6   |0.0             |
      | 1234567 | A7   |0.0             |
      | 1234567 | A8   |0.0             |
      | 1234567 | A9   |0.0             |
      | 1234567 | A10  |0.0             |
      | 1234567 | A11  |0.0722          |
      | 1234567 | A12  |0.0794          |
      | 1234567 | B1   |53.0664         |
      | 1234567 | B2   |51.5682         |
      | 1234567 | B3   |0.0746          |
      | 1234567 | B4   |0.0064          |
      | 1234567 | B5   |0.0             |
      | 1234567 | B6   |0.0             |
      | 1234567 | B7   |0.0             |
      | 1234567 | B8   |0.0             |
      | 1234567 | B9   |0.0             |
      | 1234567 | B10  |0.0             |
      | 1234567 | B11  |0.0064          |
      | 1234567 | B12  |0.0547          |
    Given I have a DNA QC submission for plate "1234567"
    Given I am on the show page for pipeline "DNA QC"
    When I check "Select DN1234567T for batch"
    And I select "Create Batch" from the first "action_on_requests"
    And I press the first "Submit"
    When I follow "QC result"
    Then I should see dna qc table:
      | Well | Volume  |
      | A1   | 55.3281 |
      | B1   | 53.0664 |
      | A2   | 25.296  |
      | B2   | 51.5682 |
      | A3   | 0.1074  |
      | B3   | 0.0746  |
      | A4   | 0.0547  |
      | B4   | 0.0064  |
      | A5   | 0.0     |
      | B5   | 0.0     |
      | A6   | 0.0     |
      | B6   | 0.0     |
      | A7   | 0.0     |
      | B7   | 0.0     |
      | A8   | 0.0     |
      | B8   | 0.0     |
      | A9   | 0.0     |
      | B9   | 0.0     |
      | A10  | 0.0     |
      | B10  | 0.0     |
      | A11  | 0.0722  |
      | B11  | 0.0064  |
      | A12  | 0.0794  |
      | B12  | 0.0547  |


  Scenario: Update measured volume results on 3 plates
    Given study "Study B" has a plate "1234567" to be volume checked
     And study "Study B" has a plate "111" to be volume checked
     And study "Study B" has a plate "222" to be volume checked
    Given all plate volume check files are processed
    Given a study report is generated for study "Study B"
     And I am on the Qc reports homepage
    Then I follow "Download report for Study B"
    Then I should see the report for "Study B":
      | Plate   | Well | Measured Volume |
      | 1234567 | A1   | 55.3281         |
      | 1234567 | A2   | 25.296          |
      | 1234567 | A3   | 0.1074          |
      | 1234567 | A4   | 0.0547          |
      | 1234567 | A5   | 0.0             |
      | 1234567 | A6   | 0.0             |
      | 1234567 | A7   | 0.0             |
      | 1234567 | A8   | 0.0             |
      | 1234567 | A9   | 0.0             |
      | 1234567 | A10  | 0.0             |
      | 1234567 | A11  | 0.0722          |
      | 1234567 | A12  | 0.0794          |
      | 1234567 | B1   | 53.0664         |
      | 1234567 | B2   | 51.5682         |
      | 1234567 | B3   | 0.0746          |
      | 1234567 | B4   | 0.0064          |
      | 1234567 | B5   | 0.0             |
      | 1234567 | B6   | 0.0             |
      | 1234567 | B7   | 0.0             |
      | 1234567 | B8   | 0.0             |
      | 1234567 | B9   | 0.0             |
      | 1234567 | B10  | 0.0             |
      | 1234567 | B11  | 0.0064          |
      | 1234567 | B12  | 0.0547          |
      | 111     | A1   | 0.0             |
      | 111     | A2   | 5.2463          |
      | 111     | A3   | 36.2634         |
      | 111     | A4   | 0.0             |
      | 111     | A5   | 0.0             |
      | 111     | A6   | 0.0             |
      | 111     | A7   | 11.057          |
      | 111     | A8   | 0.0             |
      | 111     | A9   | 0.0389          |
      | 111     | A10  | 0.0             |
      | 111     | A11  | 0.2391          |
      | 111     | A12  | 2.4558          |
      | 111     | B1   | 8.5794          |
      | 111     | B2   | 0.0             |
      | 111     | B3   | 0.0             |
      | 111     | B4   | 0.0             |
      | 111     | B5   | 29.2206         |
      | 111     | B6   | 0.0             |
      | 111     | B7   | 0.0             |
      | 111     | B8   | 0.0             |
      | 111     | B9   | 0.0             |
      | 111     | B10  | 0.0             |
      | 111     | B11  | 3.4629          |
      | 111     | B12  | 4.4145          |
      | 222     | A1   | 41.8358         |
      | 222     | A2   | 38.8119         |
      | 222     | A3   | 43.8983         |
      | 222     | A4   | 37.163          |
      | 222     | A5   | 43.1773         |
      | 222     | A6   | 43.5993         |
      | 222     | A7   | 45.4997         |
      | 222     | A8   | 38.0517         |
      | 222     | A9   | 42.6631         |
      | 222     | A10  | 0.0             |
      | 222     | A11  | 0.0663          |
      | 222     | A12  | 0.0985          |
      | 222     | B1   | 39.2451         |
      | 222     | B2   | 40.4943         |
      | 222     | B3   | 42.1628         |
      | 222     | B4   | 39.3569         |
      | 222     | B5   | 42.7469         |
      | 222     | B6   | 36.5006         |
      | 222     | B7   | 40.5949         |
      | 222     | B8   | 36.8555         |
      | 222     | B9   | 39.0718         |
      | 222     | B10  | 0.0             |
      | 222     | B11  | 0.0             |
      | 222     | B12  | 0.0133          |


  Scenario: Update plate where there is no barcode in first column
    Given study "Study B" has a plate "111" to be volume checked
    Given all plate volume check files are processed
    Given a study report is generated for study "Study B"
     And I am on the Qc reports homepage
    Then I follow "Download report for Study B"
    Then I should see the report for "Study B":
     | Plate | Well | Measured Volume |
     | 111   | A1   | 0.0             |
     | 111   | A2   | 5.2463          |
     | 111   | A3   | 36.2634         |
     | 111   | A4   | 0.0             |
     | 111   | A5   | 0.0             |
     | 111   | A6   | 0.0             |
     | 111   | A7   | 11.057          |
     | 111   | A8   | 0.0             |
     | 111   | A9   | 0.0389          |
     | 111   | A10  | 0.0             |
     | 111   | A11  | 0.2391          |
     | 111   | A12  | 2.4558          |
     | 111   | B1   | 8.5794          |
     | 111   | B2   | 0.0             |
     | 111   | B3   | 0.0             |
     | 111   | B4   | 0.0             |
     | 111   | B5   | 29.2206         |
     | 111   | B6   | 0.0             |
     | 111   | B7   | 0.0             |
     | 111   | B8   | 0.0             |
     | 111   | B9   | 0.0             |
     | 111   | B10  | 0.0             |
     | 111   | B11  | 3.4629          |
     | 111   | B12  | 4.4145          |
