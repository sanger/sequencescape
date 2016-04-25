@api @json @pulldown @submission @single-sign-on @new-api @barcode-service @pulldown_api @wip
Feature: Beginning with the API progress through pulldown to sequencing

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given I have an "active" study called "Study A"
    And the UUID for the study "Study A" is "22222222-3333-4444-5555-000000000000"

    Given plate "1234567" with 3 samples in study "Study A" exists
    Given plate "1234567" has nonzero concentration results

    Given I have a project called "Testing submission creation"
    And the UUID for the project "Testing submission creation" is "22222222-3333-4444-5555-000000000001"


    Given the UUID for the request type "Cherrypicking for Pulldown" is "99999999-1111-2222-3333-000000000000"
    And the UUID for the request type "Pulldown Multiplex Library Preparation" is "99999999-1111-2222-3333-000000000001"
    And the UUID for the request type "HiSeq Paired end sequencing" is "99999999-1111-2222-3333-000000000002"

    Given the UUID for well 1 on plate "1234567" is "44444444-2222-3333-4444-000000000001"
    And the UUID for well 2 on plate "1234567" is "44444444-2222-3333-4444-000000000002"
    And the UUID for well 3 on plate "1234567" is "44444444-2222-3333-4444-000000000003"

  Scenario: Create a submission where there are different number of lanes requested for 3 submissions
    Given I have an "active" study called "Study B"
    And the UUID for the study "Study B" is "22222222-3333-4444-6666-000000000000"
    Given plate "222" with 3 samples in study "Study B" exists
    Given plate "222" has nonzero concentration results
    Given I have an "active" study called "Study C"
    And the UUID for the study "Study C" is "22222222-3333-4444-7777-000000000000"
    Given plate "333" with 3 samples in study "Study C" exists
    Given plate "333" has nonzero concentration results

    Given the UUID for well 1 on plate "222" is "44444444-2222-3333-4444-000000000004"
    And the UUID for well 2 on plate "222" is "44444444-2222-3333-4444-000000000005"
    And the UUID for well 3 on plate "222" is "44444444-2222-3333-4444-000000000006"
    And the UUID for well 1 on plate "333" is "44444444-2222-3333-4444-000000000007"
    And the UUID for well 2 on plate "333" is "44444444-2222-3333-4444-000000000008"
    And the UUID for well 3 on plate "333" is "44444444-2222-3333-4444-000000000009"

    Given the UUID for the submission template "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing" is "00000000-1111-2222-3333-444444444444"

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666665"

    Given I have an order created with the following details based on the template "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                             |
      | project         | 22222222-3333-4444-5555-000000000001                                                                             |
      | request_options | read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: Standard       |
      | assets          | 44444444-2222-3333-4444-000000000001, 44444444-2222-3333-4444-000000000002, 44444444-2222-3333-4444-000000000003 |
    Given the order with UUID "11111111-2222-3333-4444-666666666665" is for 7 "HiSeq Paired end sequencing" requests
    When the order with UUID "11111111-2222-3333-4444-666666666665" has been added to a submission

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-555555555556"
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

    Given I have an order created with the following details based on the template "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing":
      | study           | 22222222-3333-4444-6666-000000000000                                                                             |
      | project         | 22222222-3333-4444-5555-000000000001                                                                             |
      | request_options | read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: Standard       |
      | assets          | 44444444-2222-3333-4444-000000000004, 44444444-2222-3333-4444-000000000005, 44444444-2222-3333-4444-000000000006 |
    Given the order with UUID "11111111-2222-3333-4444-666666666666" is for 5 "HiSeq Paired end sequencing" requests
    When the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-555555555557"
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666667"

    Given I have an order created with the following details based on the template "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing":
      | study           | 22222222-3333-4444-7777-000000000000                                                                             |
      | project         | 22222222-3333-4444-5555-000000000001                                                                             |
      | request_options | read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: Standard       |
      | assets          | 44444444-2222-3333-4444-000000000007, 44444444-2222-3333-4444-000000000008, 44444444-2222-3333-4444-000000000009 |
    When the order with UUID "11111111-2222-3333-4444-666666666667" has been added to a submission

    Given all submissions have been built
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" is ready
    Then the submission with UUID "11111111-2222-3333-4444-555555555556" is ready
    Then the submission with UUID "11111111-2222-3333-4444-555555555557" is ready

    Given I have a tag group called "UK10K tag group" with 3 tags
    Given I am a "administrator" user logged in as "user"
    And the "96 Well Plate" barcode printer "xyz" exists
    Given a plate barcode webservice is available and returns "99999"
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN1234567T for batch"
    And I check "Select DN222J for batch"
    And I check "Select DN333P for batch"

    And I select "Create Batch" from the first "Action to perform"
    And I press the first "Submit"
    When I follow "Cherrypick Group By Submission"
    When I fill in "Volume Required" with "13"
    And I fill in "Concentration Required" with "50"
    And I select "Pulldown Aliquot" from "Plate Purpose"
    And I press "Next step"
    When I press "Release this batch"
    When I set Plate "1220099999705" to be in freezer "Pulldown freezer"

    Given I am on the show page for pipeline "Pulldown Multiplex Library Preparation"
    When I check "Select DN99999F for batch"
    And I select "Create Batch" from the first "Action to perform"
    And I press the first "Submit"
    When I follow "Tag Groups"

    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    Then I should see "Assign Tags to Wells"
    When I press "Next step"
    When I press "Release this batch"
    Then I should see "Batch released!"

    Given all library tube barcodes are set to know values
    Then library "3980000001795" should have 7 sequencing requests
    And library "3980000002808" should have 5 sequencing requests
    And library "3980000003812" should have 1 sequencing requests

    When I set Pulldown Multiplexed Library "3980000001795" to be in freezer "Cluster formation freezer"
    And I set Pulldown Multiplexed Library "3980000002808" to be in freezer "Cluster formation freezer"
    And I set Pulldown Multiplexed Library "3980000003812" to be in freezer "Cluster formation freezer"

    Given I am on the show page for pipeline "HiSeq Cluster formation PE (no controls)"
    Then the pipeline inbox should be:
      | Available requests                                | Asset ID |  Asset type                     |  Study   |
      | Select PulldownMultiplexedLibraryTube 3 for batch | 3        |  PulldownMultiplexedLibraryTube |  Study C |
      | Select PulldownMultiplexedLibraryTube 2 for batch | 2        |  PulldownMultiplexedLibraryTube |  Study B |
      | Select PulldownMultiplexedLibraryTube 2 for batch | 2        |  PulldownMultiplexedLibraryTube |  Study B |
      | Select PulldownMultiplexedLibraryTube 2 for batch | 2        |  PulldownMultiplexedLibraryTube |  Study B |
      | Select PulldownMultiplexedLibraryTube 2 for batch | 2        |  PulldownMultiplexedLibraryTube |  Study B |
      | Select PulldownMultiplexedLibraryTube 2 for batch | 2        |  PulldownMultiplexedLibraryTube |  Study B |
      | Select PulldownMultiplexedLibraryTube 1 for batch | 1        |  PulldownMultiplexedLibraryTube |  Study A |
      | Select PulldownMultiplexedLibraryTube 1 for batch | 1        |  PulldownMultiplexedLibraryTube |  Study A |
      | Select PulldownMultiplexedLibraryTube 1 for batch | 1        |  PulldownMultiplexedLibraryTube |  Study A |
      | Select PulldownMultiplexedLibraryTube 1 for batch | 1        |  PulldownMultiplexedLibraryTube |  Study A |
      | Select PulldownMultiplexedLibraryTube 1 for batch | 1        |  PulldownMultiplexedLibraryTube |  Study A |
      | Select PulldownMultiplexedLibraryTube 1 for batch | 1        |  PulldownMultiplexedLibraryTube |  Study A |
      | Select PulldownMultiplexedLibraryTube 1 for batch | 1        |  PulldownMultiplexedLibraryTube |  Study A |

  Scenario: Create a multiple API submissions and progress all the way to sequencing
    Given I have an "active" study called "Study B"
    And the UUID for the study "Study B" is "22222222-3333-4444-6666-000000000000"
    Given plate "222" with 3 samples in study "Study B" exists
    Given plate "222" has nonzero concentration results
    Given I have an "active" study called "Study C"
    And the UUID for the study "Study C" is "22222222-3333-4444-7777-000000000000"
    Given plate "333" with 3 samples in study "Study C" exists
    Given plate "333" has nonzero concentration results
    Given the UUID for well 1 on plate "222" is "44444444-2222-3333-4444-000000000004"
    And the UUID for well 2 on plate "222" is "44444444-2222-3333-4444-000000000005"
    And the UUID for well 3 on plate "222" is "44444444-2222-3333-4444-000000000006"
    And the UUID for well 1 on plate "333" is "44444444-2222-3333-4444-000000000007"
    And the UUID for well 2 on plate "333" is "44444444-2222-3333-4444-000000000008"
    And the UUID for well 3 on plate "333" is "44444444-2222-3333-4444-000000000009"

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666665"

    Given I have an order created with the following details based on the template "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing":
      | study           | 22222222-3333-4444-5555-000000000000                                                                             |
      | project         | 22222222-3333-4444-5555-000000000001                                                                             |
      | request_options | read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: Standard       |
      | assets          | 44444444-2222-3333-4444-000000000001, 44444444-2222-3333-4444-000000000002, 44444444-2222-3333-4444-000000000003 |
    When the order with UUID "11111111-2222-3333-4444-666666666665" has been added to a submission

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-555555555556"
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

    Given I have an order created with the following details based on the template "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing":
      | study           | 22222222-3333-4444-6666-000000000000                                                                             |
      | project         | 22222222-3333-4444-5555-000000000001                                                                             |
      | request_options | read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: Standard       |
      | assets          | 44444444-2222-3333-4444-000000000004, 44444444-2222-3333-4444-000000000005, 44444444-2222-3333-4444-000000000006 |
    When the order with UUID "11111111-2222-3333-4444-666666666666" has been added to a submission

    Given the UUID of the next submission created will be "11111111-2222-3333-4444-555555555557"
      And the UUID of the next order created will be "11111111-2222-3333-4444-666666666667"

    Given I have an order created with the following details based on the template "Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing":
      | study           | 22222222-3333-4444-7777-000000000000                                                                             |
      | project         | 22222222-3333-4444-5555-000000000001                                                                             |
      | request_options | read_length: 100, fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: Standard       |
      | assets          | 44444444-2222-3333-4444-000000000007, 44444444-2222-3333-4444-000000000008, 44444444-2222-3333-4444-000000000009 |
    When the order with UUID "11111111-2222-3333-4444-666666666667" has been added to a submission

    Given all submissions have been built
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" is ready
    Then the submission with UUID "11111111-2222-3333-4444-555555555556" is ready
    Then the submission with UUID "11111111-2222-3333-4444-555555555557" is ready

    Given I have a tag group called "UK10K tag group" with 3 tags
    Given I am a "administrator" user logged in as "user"
    And the "96 Well Plate" barcode printer "xyz" exists
    Given a plate barcode webservice is available and returns "99999"
    Given I am on the show page for pipeline "Cherrypicking for Pulldown"
    When I check "Select DN1234567T for batch"
    And I check "Select DN222J for batch"
    And I check "Select DN333P for batch"

    And I select "Create Batch" from the first "Action to perform"
    And I press the first "Submit"
    When I follow "Cherrypick Group By Submission"
    When I fill in "Volume Required" with "13"
    And I fill in "Concentration Required" with "50"
    And I select "Pulldown Aliquot" from "Plate Purpose"
    And I press "Next step"
    When I press "Release this batch"
    When I set Plate "1220099999705" to be in freezer "Pulldown freezer"

    Given I am on the show page for pipeline "Pulldown Multiplex Library Preparation"
    When I check "Select DN99999F for batch"
    And I select "Create Batch" from the first "Action to perform"
    And I press the first "Submit"
    When I follow "Tag Groups"

    When I select "UK10K tag group" from "Tag Group"
    And I press "Next step"
    Then I should see "Assign Tags to Wells"
    When I press "Next step"
    When I press "Release this batch"
    Given all library tube barcodes are set to know values
    Then I should see "Batch released!"
    And I follow "Batch Report"
    When I look at the pulldown report for the batch it should be:
       | Plate    | Well | Study   | Pooled Tube | Tag Group       | Tag   | Expected Sequence | Sample Name      | Measured Volume | Measured Concentration |
       | DN99999F | A1   | Study A | 1           | UK10K tag group | Tag 1 | ATCACG            | Sample_1234567_1 | 0.0             | 1.0                    |
       | DN99999F | B1   | Study A | 1           | UK10K tag group | Tag 2 | CGATGT            | Sample_1234567_2 | 11.0            | 40.0                   |
       | DN99999F | C1   | Study A | 1           | UK10K tag group | Tag 3 | TTAGGC            | Sample_1234567_3 | 22.0            | 80.0                   |
       | DN99999F | D1   | Study B | 2           | UK10K tag group | Tag 1 | ATCACG            | Sample_222_1     | 0.0             | 1.0                    |
       | DN99999F | E1   | Study B | 2           | UK10K tag group | Tag 2 | CGATGT            | Sample_222_2     | 11.0            | 40.0                   |
       | DN99999F | F1   | Study B | 2           | UK10K tag group | Tag 3 | TTAGGC            | Sample_222_3     | 22.0            | 80.0                   |
       | DN99999F | G1   | Study C | 3           | UK10K tag group | Tag 1 | ATCACG            | Sample_333_1     | 0.0             | 1.0                    |
       | DN99999F | H1   | Study C | 3           | UK10K tag group | Tag 2 | CGATGT            | Sample_333_2     | 11.0            | 40.0                   |
       | DN99999F | A2   | Study C | 3           | UK10K tag group | Tag 3 | TTAGGC            | Sample_333_3     | 22.0            | 80.0                   |


  Scenario Outline: Create a single API submission and progress all the way to sequencing
    Given the UUID for the submission template "<submission_template_name>" is "00000000-1111-2222-3333-444444444444"
    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

    When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/orders":
      """
      {
        "order": {
          "project": "22222222-3333-4444-5555-000000000001",
          "study": "22222222-3333-4444-5555-000000000000"
        }
      }
      """
    Then the HTTP response should be "201 Created"
    And the JSON should match the following for the specified fields:
      """
      {
        "order": {
          "actions": {
            "read": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666",
            "update": "http://www.example.com/api/1/11111111-2222-3333-4444-666666666666"
          },
          "study": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000000"
            },
            "name": "Study A"
          },
          "project": {
            "actions": {
              "read": "http://www.example.com/api/1/22222222-3333-4444-5555-000000000001"
            },
            "name": "Testing submission creation"
          },
          "assets": []
        }
      }
      """
    When I PUT the following JSON to the API path "/11111111-2222-3333-4444-666666666666":
        """
        {
          "order": {
            "assets": [
              "44444444-2222-3333-4444-000000000001",
              "44444444-2222-3333-4444-000000000002",
              "44444444-2222-3333-4444-000000000003"
            ],
            "request_options": {
              "read_length": <read_length>,
              "fragment_size_required": {
                "from": 100,
                "to": 200
              },
              "library_type": "Standard"
            }
          }
        }
        """
     Then the HTTP response should be "200 OK"
     When I POST the following JSON to the API path "/submissions":
      """
      {
        "submission": {
          "orders": [
            "11111111-2222-3333-4444-666666666666"
          ]
        }
      }
      """
     Then the HTTP response should be "201 Created"
     When I POST the following JSON to the API path "/11111111-2222-3333-4444-555555555555/submit":
       """
       """
     Then the HTTP response should be "200 OK"
     Given all pending delayed jobs are processed
     Then the submission with UUID "11111111-2222-3333-4444-555555555555" is ready

     Given I have a tag group called "UK10K tag group" with 4 tags
     Given I am a "administrator" user logged in as "user"
     And the "96 Well Plate" barcode printer "xyz" exists
     Given a plate barcode webservice is available and returns "99999"
     Given I am on the show page for pipeline "Cherrypicking for Pulldown"
     When I check "Select DN1234567T for batch"
     And I select "Create Batch" from the first "Action to perform"
     And I press the first "Submit"
     When I follow "Cherrypick Group By Submission"
     When I fill in "Volume Required" with "13"
     And I fill in "Concentration Required" with "50"
     And I select "Pulldown Aliquot" from "Plate Purpose"
     And I press "Next step"
     When I press "Release this batch"
     When I set Plate "1220099999705" to be in freezer "Pulldown freezer"
     Given I am on the show page for pipeline "Pulldown Multiplex Library Preparation"
     When I check "Select DN99999F for batch"
     And I select "Create Batch" from the first "Action to perform"
     And I press the first "Submit"
     When I follow "Tag Groups"
     When I select "UK10K tag group" from "Tag Group"
     And I press "Next step"
     And I press "Next step"
     When I press "Release this batch"
     Given all library tube barcodes are set to know values
     When I set Pulldown Multiplexed Library "3980000001795" to be in freezer "Cluster formation freezer"
     Given I am on the show page for pipeline "<sequencing_pipeline_name>"
     When I check "Select PulldownMultiplexedLibraryTube 1 for batch"
     And I select "Create Batch" from the first "Action to perform"
     And I press the first "Submit"
     And I follow "Specify Dilution Volume"
     And I press "Next step"
     And I press "Next step"
     And I press "Next step"
     And I press "Next step"
     And I press "Next step"
     When I press "Release this batch"
     Then I should see "Batch released!"

     Examples:
      | submission_template_name                                                                          | sequencing_pipeline_name                 | read_length |
      | Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - HiSeq Paired end sequencing | HiSeq Cluster formation PE (no controls) | 100         |
      | Cherrypicking for Pulldown - Pulldown Multiplex Library Preparation - Paired end sequencing       | Cluster formation PE                     | 108         |
