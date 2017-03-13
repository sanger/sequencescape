@slf @sequenom @qc_overview
Feature: display an overview of all plates going through QC in SLF

   Background:
     Given I am an "slf_manager" user logged in as "john"
     And I have an active study called "Test Study"
     And there is a 1 well "Stock Plate" plate with a barcode of "1221234567841"
     And asset with barcode "1221234567841" belongs to study "Test study"
     And the "96 Well Plate" barcode printer "xyz" exists
     And I am on the sample logistics homepage
     Given all of this is happening at exactly "14-Feb-2011 23:00:00+01:00"
     Given user "jack" exists with barcode "ID100I"

   Scenario: A plate hasnt started QC
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study | Stock | QC started | Pico Analysed | Gel Analysed | Sequenom Stamp |

   @qc_event @barcode-service
   Scenario: A plate has only had a dilution plates created
     When I follow "Sample Management Lab View"
     And I follow "Print plate barcodes"
     Then I create a "Working dilution" from plate "1221234567841"
     Given plate "1221234567841" is part of study "Test study"
     Given I am on the sample logistics homepage
     When I follow "QC overview"
     Then the overview of the plates should look like:
       | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
       | Test Study | 1234567 | 2011-02-14        |               |              |                |
     Given I am on the Qc reports homepage
      When I select "Test Study" from "Study"
     And I press "Submit"
      Given 1 pending delayed jobs are processed
      And I am on the Qc reports homepage
      When I follow "Download report for Test Study"
     Then I should see the report for "Test Study":
       | Well | QC started date |
       | A1   | 2011-02-14      |


   @barcode-service
   Scenario: A plate has had pico assays created but not analysed
     When I follow "Sample Management Lab View"
     And I follow "Print plate barcodes"
     Then I create a "Working dilution" from plate "1221234567841"
     Then I create a "Pico dilution" from plate "6251234567836"
     Then I create a "Pico Assay Plates" from plate "4361234567667"
     Given I am on the sample logistics homepage
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
     | Test Study | 1234567 | 2011-02-14        |               |              |                |

   @barcode-service
   Scenario: A plate has had pico assays and has been analysed
     When I follow "Sample Management Lab View"
     And I follow "Print plate barcodes"
     Then I create a "Working dilution" from plate "1221234567841"
     Then I create a "Pico dilution" from plate "6251234567836"
     Then I create a "Pico Assay Plates" from plate "4361234567667"
     Given plate "1221234567841" has had pico analysis results uploaded
     Given I am on the sample logistics homepage
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
     | Test Study | 1234567 | 2011-02-14        | 2011-02-14    |              |                |

   @barcode-service
   Scenario: A plate has only completed Gel
     When I follow "Sample Management Lab View"
     And I follow "Print plate barcodes"
     Then I create a "Working dilution" from plate "1221234567841"
     Then I create a "Gel Dilution Plates" from plate "6251234567836"
     Given plate "1221234567841" has gel analysis results
     Given I am on the sample logistics homepage
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
     | Test Study | 1234567 | 2011-02-14        |               | 2011-02-14   |                |

   @barcode-service
   Scenario: A plate hasnt had a sequenom plate generated
     When I follow "Sample Management Lab View"
     And I follow "Print plate barcodes"
     Then I create a "Working dilution" from plate "1221234567841"
     Then I create a "Pico dilution" from plate "6251234567836"
     Then I create a "Pico Assay Plates" from plate "4361234567667"
     Then I create a "Gel Dilution Plates" from plate "6251234567836"
     Given plate "1221234567841" has gel analysis results
     Given plate "1221234567841" has had pico analysis results uploaded
     Given I am on the sample logistics homepage
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
     | Test Study | 1234567 | 2011-02-14        | 2011-02-14    | 2011-02-14   |                |

  @barcode-service @qc_event
   Scenario: A plate has fully completed QC
     Given the plate barcode webservice returns "11111"
     Given plate "1221234567841" is part of study "Test study"

     When I follow "Sample Management Lab View"
     And I follow "Print plate barcodes"
     Then I create a "Working dilution" from plate "1221234567841"
     Then I create a "Pico dilution" from plate "6251234567836"
     Then I create a "Pico Assay Plates" from plate "4361234567667"
     Then I create a "Gel Dilution Plates" from plate "6251234567836"
     Given I am on the sample logistics homepage
     When I follow "Sample Management Lab View"
     And I follow "Print Sequenom plate barcode"
     When I fill in "Plate 1" with "6251234567836"
     And I fill in "User barcode" with "2470000100730"
     And I fill in "Number of Plates" with "1"
     And select "QC" from "Plate Type"
     And select "xyz" from "Barcode Printer"
     And I press "Create new Plate"
     Given I am on the sample logistics homepage
     Given plate "1221234567841" has gel analysis results
     Given plate "1221234567841" has had pico analysis results uploaded
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
     | Test Study | 1234567 | 2011-02-14        | 2011-02-14    | 2011-02-14   | 2011-02-14     |

     Given I am on the Qc reports homepage
      When I select "Test Study" from "Study"
     And I press "Submit"
      Given 2 pending delayed jobs are processed
      And I am on the Qc reports homepage
      When I follow "Download report for Test Study"
     Then I should see the report for "Test Study":
       | Well | QC started date | Seq stamp date |
       | A1   | 2011-02-14      | 2011-02-14     |


  @new-api @asset_audit @single-sign-on
  Scenario: A plate has been scanned as received in the audit application
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"
    Given the plate exists with ID 1000
    And the UUID for the plate with ID 1000 is "00000000-1111-2222-3333-555555555555"
    And plate 1000 has is a stock plate
    Given the UUID of the next asset audit created will be "00000000-1111-2222-3333-444444444444"
    When I make an authorised POST with the following JSON to the API path "/asset_audits":
      """
      {
        "asset_audit": {
          "message": "Process 'Receive plates' performed on instrument Reception fridge",
          "key": "slf_receive_plates",
          "created_by": "john",
          "asset": "00000000-1111-2222-3333-555555555555",
          "witnessed_by": "jane"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    Given I am on the sample logistics homepage
    When I follow "QC overview"
    Then the overview of the plates should look like:
      | Received   | QC started  | Pico Analysed | Gel Analysed | Sequenom Stamp |
      | 2011-02-14 |             |               |              |                |

  @new-api @asset_audit @single-sign-on
  Scenario: A plate has been scanned as having been volume checked by the audit application
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"
    Given the plate exists with ID 1000
    And the UUID for the plate with ID 1000 is "00000000-1111-2222-3333-555555555555"
    And plate 1000 has is a stock plate

    Given the UUID of the next asset audit created will be "00000000-1111-2222-3333-444444444444"
    When I make an authorised POST with the following JSON to the API path "/asset_audits":
      """
      {
        "asset_audit": {
          "message": "Process 'Receive plates' performed on instrument Reception fridge",
          "key": "slf_receive_plates",
          "created_by": "john",
          "asset": "00000000-1111-2222-3333-555555555555"
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Given the UUID of the next asset audit created will be "00000000-1111-2222-3333-444444444444"
    When I make an authorised POST with the following JSON to the API path "/asset_audits":
      """
      {
        "asset_audit": {
          "message": "Process 'Volume check' performed on instrument Volume checker",
          "key": "slf_volume_check",
          "created_by": "john",
          "asset": "00000000-1111-2222-3333-555555555555"
        }
      }
      """
    Then the HTTP response should be "201 Created"

    Given I am on the sample logistics homepage
    When I follow "QC overview"
    Then the overview of the plates should look like:
      | Received   | QC started | Volume Check   | Pico Analysed | Gel Analysed | Sequenom Stamp |
      | 2011-02-14 |            | 2011-02-14     |               |              |                |
