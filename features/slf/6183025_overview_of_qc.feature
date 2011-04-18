@slf @sequenom @qc_overview
Feature: display an overview of all plates going through QC in SLF

   Background:
     Given I am an "slf_manager" user logged in as "john"
     And I have an active study called "Test Study"
     # And a "Stock Plate" plate purpose and of type "Plate" with barcode "1221234567841" exists
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
     When I follow "SLF Lab view"
     And I follow "Print plate barcodes"
     Then I create a "Dilution Plates" from plate "1221234567841"
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
  

   Scenario: A plate has had pico assays created but not analysed
     When I follow "SLF Lab view"
     And I follow "Print plate barcodes"
     Then I create a "Dilution Plates" from plate "1221234567841"
     Then I create a "Pico Assay Plates" from plate "4361234567667"
     Given I am on the sample logistics homepage
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
     | Test Study | 1234567 | 2011-02-14        |               |              |                |

   Scenario: A plate has had pico assays and has been analysed
     When I follow "SLF Lab view"
     And I follow "Print plate barcodes"
     Then I create a "Dilution Plates" from plate "1221234567841"
     Then I create a "Pico Assay Plates" from plate "4361234567667"
     Given plate "1221234567841" has had pico analysis results uploaded
     Given I am on the sample logistics homepage
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
     | Test Study | 1234567 | 2011-02-14        | 2011-02-14    |              |                |

   Scenario: A plate has only completed Gel
     When I follow "SLF Lab view"
     And I follow "Print plate barcodes"
     Then I create a "Dilution Plates" from plate "1221234567841"
     Then I create a "Gel Dilution Plates" from plate "6251234567836"
     Given plate "1221234567841" has gel analysis results
     Given I am on the sample logistics homepage
     When I follow "QC overview"
     Then the overview of the plates should look like:
     | Study      | Stock   | QC started        | Pico Analysed | Gel Analysed | Sequenom Stamp |
     | Test Study | 1234567 | 2011-02-14        |               | 2011-02-14   |                |

   Scenario: A plate hasnt had a sequenom plate generated
     When I follow "SLF Lab view"
     And I follow "Print plate barcodes"
     Then I create a "Dilution Plates" from plate "1221234567841"
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

     When I follow "SLF Lab view"
     And I follow "Print plate barcodes"
     Then I create a "Dilution Plates" from plate "1221234567841"
     Then I create a "Pico Assay Plates" from plate "4361234567667"
     Then I create a "Gel Dilution Plates" from plate "6251234567836"
     Given I am on the sample logistics homepage
     When I follow "SLF Lab view"
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
  
