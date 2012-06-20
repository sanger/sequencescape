@api @json @asset @search @single-sign-on @new-api @barcode_search @barcode-service
Feature: Searching for assets by barcode
  Background:
    Given all of this is happening at exactly "12-Jun-2012 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    
    Given the UUID for the search "Find illumina-b plates" is "00000000-1111-2222-3333-444444444444"
    Given the UUID for the search "Find illumina-b stock plates" is "00000000-1111-2222-3333-444444444445"
    Given the UUID for the search "Find illumina-b plates for user" is "00000000-1111-2222-3333-444444444446"
    
    Given the plate barcode webservice returns "1000001"
      And the plate barcode webservice returns "1000002"
      And the plate barcode webservice returns "1000003"
      And the plate barcode webservice returns "1000004"
      And the plate barcode webservice returns "1000005"
      
      Given a "Stock Plate" plate called "stock plate" exists
      And a "ILB_STD_INPUT" plate called "Testing the API A" exists
      And the UUID for the plate "Testing the API A" is "00000000-1111-2222-3333-000000000001"
      And all wells on the plate "Testing the API A" have unique samples
      And passed transfer requests exist between 1 wells on "stock plate" and "Testing the API A"
      And the plate with UUID "00000000-1111-2222-3333-000000000001" has been submitted to "Illumina-B STD - HiSeq Paired end sequencing"
      And a "ILB_STD_COVARIS" plate called "Testing the API B" exists
      And the UUID for the plate "Testing the API B" is "00000000-1111-2222-3333-000000000002"
      And a "ILB_STD_PCR" plate called "Testing the API C" exists
      And the UUID for the plate "Testing the API C" is "00000000-1111-2222-3333-000000000003"
      And a "ILB_STD_PCRXP" plate called "Testing the API D" exists
      And the UUID for the plate "Testing the API D" is "00000000-1111-2222-3333-000000000004"
      And pending transfer requests exist between 1 wells on "stock plate" and "Testing the API B"
      And pending transfer requests exist between 1 wells on "stock plate" and "Testing the API C"
      And pending transfer requests exist between 1 wells on "stock plate" and "Testing the API D"
      
    Scenario: I should be able to find Illumina-B Plates
      
      When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
        """
        {
          "search": {
            "state": ["pending","started","failed","passed"]
          }
        }
        """
        
        Then the HTTP response should be "300 Multiple Choices"
         And the JSON should match the following for the specified fields:
          """
          {"size":4,
           "searches":
            [
              {"name":"Testing the API A",
              "created_at":"2012-06-12T23:00:00+01:00",
              "plate_purpose":{"name":"ILB_STD_INPUT"},
              "uuid":"00000000-1111-2222-3333-000000000001",
              "updated_at":"2012-06-12T23:00:00+01:00",
              "state":"passed"},
              {"name":"Testing the API B",
              "created_at":"2012-06-12T23:00:00+01:00",
              "plate_purpose":{"name":"ILB_STD_COVARIS"},
              "uuid":"00000000-1111-2222-3333-000000000002",
              "updated_at":"2012-06-12T23:00:00+01:00",
              "state":"pending"},
              {"name":"Testing the API C",
              "created_at":"2012-06-12T23:00:00+01:00",
              "plate_purpose":{"name":"ILB_STD_PCR"},
              "uuid":"00000000-1111-2222-3333-000000000003",
              "updated_at":"2012-06-12T23:00:00+01:00",
              "state":"pending"},
              {"name":"Testing the API D",
              "created_at":"2012-06-12T23:00:00+01:00",
              "plate_purpose":{"name":"ILB_STD_PCRXP"},
              "uuid":"00000000-1111-2222-3333-000000000004",
              "updated_at":"2012-06-12T23:00:00+01:00",
              "state":"pending"}
              ]
           }

          """
          When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444444/all":
            """
            {
              "search": {
                "state": ["passed"]
              }
            }
            """

            Then the HTTP response should be "300 Multiple Choices"
             And the JSON should match the following for the specified fields:
              """
              {"size":1,
               "searches":
                [
                  {"name":"Testing the API A",
                  "created_at":"2012-06-12T23:00:00+01:00",
                  "plate_purpose":{"name":"ILB_STD_INPUT"},
                  "uuid":"00000000-1111-2222-3333-000000000001",
                  "updated_at":"2012-06-12T23:00:00+01:00",
                  "state":"passed"}
                  ]
               }
              """
      Scenario: I should be able to find Illumina-B Stock Plates
      
        When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444445/all":
         """
         {
           "search": {
             "state": ["pending","started","failed","passed"]
           }
         }
         """
         Then the HTTP response should be "300 Multiple Choices"
          And the JSON should match the following for the specified fields:
           """
           {"size":1,
            "searches":
             [
               {"name":"Testing the API A",
               "created_at":"2012-06-12T23:00:00+01:00",
               "plate_purpose":{"name":"ILB_STD_INPUT"},
               "uuid":"00000000-1111-2222-3333-000000000001",
               "updated_at":"2012-06-12T23:00:00+01:00",
               "state":"passed"}
               ]
            }
           """
      Scenario: I should be able to find plates for a particular user
        
        
        Given user "plate_owner" exists with barcode "owner"
        Given the UUID of the last user created is "00000000-1111-2222-3333-100000000001"
        Given user "plateless" exists with barcode "plateless"
        Given the UUID of the last user created is "00000000-1111-2222-3333-100000000002"
        And all wells on the plate "Testing the API B" have unique samples
        Given the plate "Testing the API B" is started by "plate_owner"
        
         When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444446/all":
           """
           {
             "search": {
               "state": ["pending","started","failed","passed"],
               "user_uuid": "00000000-1111-2222-3333-100000000001"
             }
           }
           """
         Then the HTTP response should be "300 Multiple Choices"
         And the JSON should match the following for the specified fields:
          """
          {"size":1,
           "searches":
            [
              {"name":"Testing the API B",
              "created_at":"2012-06-12T23:00:00+01:00",
              "plate_purpose":{"name":"ILB_STD_COVARIS"},
              "uuid":"00000000-1111-2222-3333-000000000002",
              "updated_at":"2012-06-12T23:00:00+01:00",
              "state":"started"}
              ]
           }
          """
          When I POST the following JSON to the API path "/00000000-1111-2222-3333-444444444446/all":
            """
            {
              "search": {
                "state": ["pending","started","failed","passed"],
                "user_uuid": "00000000-1111-2222-3333-100000000002"
              }
            }
            """
          Then the HTTP response should be "300 Multiple Choices"
          And the JSON should match the following for the specified fields:
           """
           {"size":0
            }
           """