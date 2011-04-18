@api @json @submission @single-sign-on @new-api
Feature: Access submissions through the API
  In order to actually be able to do anything useful
  As an authenticated user of the API
  I want to be able to create, read and update individual submissions through their UUID
  And I want to be able to perform other operations to individual submissions
  And I want to be able to do all of this only knowing the UUID of a submission
  And I understand I will never be able to delete a submission through its UUID

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"

    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"

    Given I am using the latest version of the API

  # "NOTE": The majority of the submission testing is in api/uk10k/submissions.feature

  @read @error
  Scenario: Reading the JSON for a UUID that does not exist
    When I GET the API path "/00000000-1111-2222-3333-444444444444"
    Then the HTTP response should be "404 Not Found"
    And the JSON should be:
      """
      {
        "general": [ "UUID does not exist" ]
      }
      """
