@slf @qc
Feature: Display QC data for a plate in a grid

  Background:
    Given I am logged in as "user"
  Scenario: A plate has holded wells
    Given a "Stock Plate" plate purpose and of type "Plate" with barcode "1220000123724" exists
      And plate "123" has "3" wells
      And I am on the show page for asset "1220000123724"
    Then the asset relations table should be:
      | Relationship type | Map |
      | Child             | A1  |
      | Child             | A2  |
      | Child             | A3  |

  Scenario: A plate has no QC results
    Given a "Stock Plate" plate purpose and of type "Plate" with barcode "1220000123724" exists
      And plate "123" has "3" wells
      And I am on the show page for asset "1220000123724"
    When I follow "QC results"
    Then the QC table for "gel_pass" should be:
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    Then the QC table for "concentration" should be:
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    Then the QC table for "measured_volume" should be:
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    Then the QC table for "sequenom_count" should be:
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |

    Then the QC table for "quantity_in_nano_grams" should be:
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      |   |   |   |   |   |   |   |   |   |    |    |    |
      | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |



  Scenario: A plate has all QC results
  Given a "Stock Plate" plate purpose and of type "Plate" with barcode "1220000123724" exists
    And plate "123" has "3" wells
    And plate "123" has QC results
    And I am on the show page for asset "1220000123724"
  When I follow "QC results"
  Then the QC table for "gel_pass" should be:
    | 1  | 2  | 3  | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    | OK | OK | OK |   |   |   |   |   |   |    |    |    |
    |    |    |    |   |   |   |   |   |   |    |    |    |
    |    |    |    |   |   |   |   |   |   |    |    |    |
    |    |    |    |   |   |   |   |   |   |    |    |    |
    |    |    |    |   |   |   |   |   |   |    |    |    |
    |    |    |    |   |   |   |   |   |   |    |    |    |
    |    |    |    |   |   |   |   |   |   |    |    |    |
    |    |    |    |   |   |   |   |   |   |    |    |    |
    | 1  | 2  | 3  | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |

  Then the QC table for "concentration" should be:
    | 1   | 2    | 3    | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    | 0.0 | 10.0 | 20.0 |   |   |   |   |   |   |    |    |    |
    |     |      |      |   |   |   |   |   |   |    |    |    |
    |     |      |      |   |   |   |   |   |   |    |    |    |
    |     |      |      |   |   |   |   |   |   |    |    |    |
    |     |      |      |   |   |   |   |   |   |    |    |    |
    |     |      |      |   |   |   |   |   |   |    |    |    |
    |     |      |      |   |   |   |   |   |   |    |    |    |
    |     |      |      |   |   |   |   |   |   |    |    |    |
    | 1   | 2    | 3    | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |

  Then the QC table for "measured_volume" should be:
    | 1   | 2   | 3    | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    | 0.0 | 5.0 | 10.0 |   |   |   |   |   |   |    |    |    |
    |     |     |      |   |   |   |   |   |   |    |    |    |
    |     |     |      |   |   |   |   |   |   |    |    |    |
    |     |     |      |   |   |   |   |   |   |    |    |    |
    |     |     |      |   |   |   |   |   |   |    |    |    |
    |     |     |      |   |   |   |   |   |   |    |    |    |
    |     |     |      |   |   |   |   |   |   |    |    |    |
    |     |     |      |   |   |   |   |   |   |    |    |    |
    | 1   | 2   | 3    | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |

  Then the QC table for "sequenom_count" should be:
    | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    | 0 | 1 | 2 |   |   |   |   |   |   |    |    |    |
    |   |   |   |   |   |   |   |   |   |    |    |    |
    |   |   |   |   |   |   |   |   |   |    |    |    |
    |   |   |   |   |   |   |   |   |   |    |    |    |
    |   |   |   |   |   |   |   |   |   |    |    |    |
    |   |   |   |   |   |   |   |   |   |    |    |    |
    |   |   |   |   |   |   |   |   |   |    |    |    |
    |   |   |   |   |   |   |   |   |   |    |    |    |
    | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |

  Then the QC table for "quantity_in_nano_grams" should be:
    | 1 | 2  | 3   | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |
    | 0 | 50 | 200 |   |   |   |   |   |   |    |    |    |
    |   |    |     |   |   |   |   |   |   |    |    |    |
    |   |    |     |   |   |   |   |   |   |    |    |    |
    |   |    |     |   |   |   |   |   |   |    |    |    |
    |   |    |     |   |   |   |   |   |   |    |    |    |
    |   |    |     |   |   |   |   |   |   |    |    |    |
    |   |    |     |   |   |   |   |   |   |    |    |    |
    |   |    |     |   |   |   |   |   |   |    |    |    |
    | 1 | 2  | 3   | 4 | 5 | 6 | 7 | 8 | 9 | 10 | 11 | 12 |



