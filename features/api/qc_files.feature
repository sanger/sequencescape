@api @json @plate @single-sign-on @new-api
Feature: Access plate QC Information through the api
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to attatch an arbitary number of QC files to plates
  And I should be able to retrieve a list of attatched QC files
  AND I should be able to retrieve individual QC files

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    And all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given I am using the latest version of the API

  @read
  Scenario: Reading the JSON for a UUID
    Given the plate exists with ID 1
      And the plate with ID 1 has a barcode of "1220000001831"
      And the UUID for the plate with ID 1 is "00000000-1111-2222-3333-444444444444"
      And the plate with ID 1 has a plate purpose of "Stock plate"
      And the UUID for the plate purpose "Stock plate" is "11111111-2222-3333-4444-555555555555"
      And the plate with ID 1 has attatched QC data with a UUID of "11111111-2222-3333-4444-666666666666"

    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "plate": {
          "actions": {
            "read": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444"
          },
          "qc_information" : {
            "actions": {
              "read":   "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/qc_information",
              "create": "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/qc_information"
            }
          }
        }
      }
      """
    When I GET the API path "/00000000-1111-2222-3333-444444444444/qc_information"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
        "actions":{
          "read":  "http://localhost:3000/api/1/00000000-1111-2222-3333-444444444444/qc_information/1",
          "first": "http://localhost:3000/api/1/00000000-1111-2222-3333-444444444444/qc_information/1",
          "last":  "http://localhost:3000/api/1/00000000-1111-2222-3333-444444444444/qc_information/1"
        },
        "size":1,
        "qc_information":[
          {
            "created_at":"2010-10-23 23:00:00 +0100",
            "updated_at":"2010-10-23 23:00:00 +0100",
            "filename":"example_file.txt",
            "actions":{"read":"http://localhost:3000/api/1/11111111-2222-3333-4444-666666666666"},
            "uuid":"11111111-2222-3333-4444-666666666666"
          }
        ]
      }
      """
