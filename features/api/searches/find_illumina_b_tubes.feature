@api @json @asset @search @single-sign-on @new-api @barcode_search @barcode-service
Feature: Searching for assets by barcode
  Background:
    Given all of this is happening at exactly "12-Jun-2012 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    
    Given the UUID for the search "Find Illumina-B tubes" is "00000000-1111-2222-3333-444444444444"
      
      # Flow 1 [Stock]
      Given I am setup to test tubes with plate set 1
      # A standard stock tube with requests in, but not out
      # Should appear
      Given a "ILB_STD_STOCK" tube called "stock tube current" exists
      And the UUID for the tube "stock tube current" is "00000000-1111-2222-3333-000000000001"
      And the tube "stock tube current" is the target of a started "Transfer" from "middle plate 1"
      
      # An MX tube at the beginning of the process, no transfer requests in or out
      # Shouldn't Appear
      Given a "ILB_STD_MX" tube called "mx tube pending" exists
      And the UUID for the tube "mx tube pending" is "00000000-1111-2222-3333-000000000003"
      And the tube "mx tube pending" is the target of a started "Illumina-B STD" from "source plate 1"
      
      # Flow B [MX]
      Given I am setup to test tubes with plate set 2
      # A stock tube which has been multiplexed
      # Shouldn't Appear XXX
      Given a "ILB_STD_STOCK" tube called "stock tube passed" exists
      And the UUID for the tube "stock tube passed" is "00000000-1111-2222-3333-000000000002"
      And the tube "stock tube passed" is the target of a passed "Transfer" from "middle plate 2"
      # An MX tube with requests in, but not yet out
      # Should Appear
      Given a "ILB_STD_MX" tube called "mx tube current" exists
      And the UUID for the tube "mx tube current" is "00000000-1111-2222-3333-000000000004"
      And the tube "mx tube current" is the target of a started "Illumina-B STD" from "source plate 2"
      And a started transfer from the stock tube "stock tube passed" to the MX tube
      
      # Flow C [MX]
      Given I am setup to test tubes with plate set 3
      
      Given a "ILB_STD_STOCK" tube called "stock tube passed 3" exists
      And the UUID for the tube "stock tube passed 3" is "00000000-1111-2222-3333-000000000006"
      And the tube "stock tube passed 3" is the target of a passed "Transfer" from "middle plate 3"

      Given a "ILB_STD_MX" tube called "mx tube passed" exists
      And the UUID for the tube "mx tube passed" is "00000000-1111-2222-3333-000000000005"
      And the tube "mx tube passed" is the target of a passed "Illumina-B STD" from "source plate 3"
      #And the tube "mx tube passed" is the target of a passed "Transfer" from "further stock tube passed"
      And a passed transfer from the stock tube "stock tube passed 3" to the MX tube
      #And the transfer requests on "stock tube passed 3" are passed
      
    Scenario: I should be able to find Illumina-B Tubes
      
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
          {"size":2,
           "searches":
            [
              {"name":"stock tube current",
              "created_at":"2012-06-12T23:00:00+01:00",
              "purpose":{"name":"ILB_STD_STOCK"},
              "uuid":"00000000-1111-2222-3333-000000000001",
              "updated_at":"2012-06-12T23:00:00+01:00",
              "state":"started"},
              {"name":"stock tube passed",
              "created_at":"2012-06-12T23:00:00+01:00",
              "purpose":{"name":"ILB_STD_MX"},
              "uuid":"00000000-1111-2222-3333-000000000004",
              "updated_at":"2012-06-12T23:00:00+01:00",
              "state":"started"}
              ]
           }

          """
