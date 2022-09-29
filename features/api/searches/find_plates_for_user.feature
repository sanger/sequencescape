@api @json @asset @search @single-sign-on @new-api @barcode_search @barcode-service
Feature: Searching for assets by barcode
  Background:
    Given all of this is happening at exactly "12-Jun-2012 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

    Given the UUID for the search "Find Illumina-C plates for user" is "00000000-1111-2222-3333-444444444446"

      Given a "Stock Plate" plate called "stock plate" exists with barcode "SQPD-1000001"
      And a "ILC Stock" plate called "Testing the API A" exists with barcode "SQPD-1000002"
      And the UUID for the plate "Testing the API A" is "00000000-1111-2222-3333-000000000001"
      And all wells on the plate "Testing the API A" have unique samples
      And passed transfer requests exist between 1 wells on "stock plate" and "Testing the API A"
      And a "ILC AL Libs" plate called "Testing the API B" exists with barcode "SQPD-1000003"
      And the UUID for the plate "Testing the API B" is "00000000-1111-2222-3333-000000000002"
      And a "ILC Lib PCR" plate called "Testing the API C" exists with barcode "SQPD-1000004"
      And the UUID for the plate "Testing the API C" is "00000000-1111-2222-3333-000000000003"
      And a "ILC Lib PCR-XP" plate called "Testing the API D" exists with barcode "SQPD-1000005"
      And the UUID for the plate "Testing the API D" is "00000000-1111-2222-3333-000000000004"
      And a "Cherrypicked" plate called "Testing the API E" exists with barcode "SQPD-1000006"
      And the UUID for the plate "Testing the API D" is "00000000-1111-2222-3333-000000000005"
      And pending transfer requests exist between 1 wells on "stock plate" and "Testing the API B"
      And pending transfer requests exist between 1 wells on "stock plate" and "Testing the API C"
      And pending transfer requests exist between 1 wells on "stock plate" and "Testing the API D"

    Scenario: I should be able to find plates for a particular user
        Given user "plate_owner" exists with barcode "owner"
        Given the UUID of the last user created is "00000000-1111-2222-3333-100000000001"
        Given user "plateless" exists with barcode "plateless"
        Given the UUID of the last user created is "00000000-1111-2222-3333-100000000002"
        And there is an asset link between "Stock Plate" and "Testing the API B"

        Given the plate "Testing the API B" is started by "plate_owner"
        Given the plate "Testing the API C" is started by "plate_owner"
        Given the plate "Testing the API E" is started by "plate_owner"

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
          {"size":2,
           "searches":
            [
              {"name":"Testing the API C",
              "plate_purpose":{"name":"ILC Lib PCR"},
              "uuid":"00000000-1111-2222-3333-000000000003",
              "state":"started"},
              {"name":"Testing the API B",
              "plate_purpose":{"name":"ILC AL Libs"},
              "uuid":"00000000-1111-2222-3333-000000000002",
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
