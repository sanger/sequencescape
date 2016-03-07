@api @json @plate @single-sign-on @new-api
Feature: Access plates through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual plates through their UUID
  And I want to be able to perform other operations to individual plates
  And I want to be able to do all of this only knowing the UUID of a plate
  And I understand I will never be able to delete a plate through its UUID

  Background:
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API
And I have a "full" authorised user with the key "cucumber"

    Given the plate exists with ID 1
    And the plate with ID 1 has a plate purpose of "Cherrypicked"
    And the UUID for the plate with ID 1 is "00000000-1111-2222-3333-444444444444"

  @read
  Scenario: Without a submission
    When I GET the API path "/00000000-1111-2222-3333-444444444444/submission_pools"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
      "actions":
        {"read":
          "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/submission_pools/1",
         "first":
          "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/submission_pools/1",
         "last":
          "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/submission_pools/1"},
       "size": 0,
       "submission_pools": []
       }
      """

  @read
  Scenario: With a submission and a used template
    Given the plate with ID 1 has a barcode of "1220000001831"
    And plate "1" has "2" wells with samples
    Given the plate with UUID "00000000-1111-2222-3333-444444444444" has been submitted to "Illumina-B - Pooled PATH - HiSeq Paired end sequencing"
    And the tag 2 layout template "test template" exists
    And the UUID for the last tag2 layout template is "00000000-2222-2222-3333-444444444444"
    And the tag2 layout template "test template" is associated with the last submission
    When I GET the API path "/00000000-1111-2222-3333-444444444444/submission_pools"
    Then the HTTP response should be "200 OK"
    And the JSON should match the following for the specified fields:
      """
      {
      "actions":
        {"read":
          "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/submission_pools/1",
         "first":
          "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/submission_pools/1",
         "last":
          "http://www.example.com/api/1/00000000-1111-2222-3333-444444444444/submission_pools/1"},
       "size":1,
       "submission_pools":[{
          "plates_in_submission":1,
          "used_tag2_layout_templates":[{"uuid":"00000000-2222-2222-3333-444444444444","name":"test template"}]
       }]
       }
      """
