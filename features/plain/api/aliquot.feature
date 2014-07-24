@api @json @aliquot @allow-rescue
Feature: Interacting with aliquot through the API
 Background:
    Given all of this is happening at exactly "16-September-2010 13:45:00+01:00"
    Given I am using version "0_5" of a legacy API

 Scenario: List all of the aliquots that exist it there aren't any
     When I GET the API path "/aliquots"
      Then the JSON should be an empty array

  Scenario: Listing all of the aliquots that exist
    Given I am logged in as "John Smith"
    Given I have a study called "test study"
    Given study "test study" has a registered sample "sample"
    And all assets have sequential UUIDs based on "aaaaaaaa-1111-2222-3333"
    And all samples have sequential UUIDs based on "bbbbbbbb-1111-2222-3333"
    Given the UUID for the last aliquot is "22222222-2222-3333-4444-ffffffffffff"

    When I GET the API path "/aliquots/22222222-2222-3333-4444-ffffffffffff"
    Then ignoring "internal_id|id" the JSON should be:
    """
    {
      "aliquot": {
         "created_at": "2010-09-16T13:45:00+01:00",
         "updated_at": "2010-09-16T13:45:00+01:00",
         "uuid": "22222222-2222-3333-4444-ffffffffffff",
         "receptacle_url": "http://localhost:3000/0_5/sample_tubes/aaaaaaaa-1111-2222-3333-000000000001",
         "receptacle_uuid": "aaaaaaaa-1111-2222-3333-000000000001",
         "receptacle_type": "sample_tube",
         "sample_url": "http://localhost:3000/0_5/samples/bbbbbbbb-1111-2222-3333-000000000002",
         "sample_uuid": "bbbbbbbb-1111-2222-3333-000000000002"
      }
    }
    """
