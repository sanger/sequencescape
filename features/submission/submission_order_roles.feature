@api @json @submission @mutiple_orders @order @barcode-service @single-sign-on @new-api
Feature: Submission templates should set order roles

  Background:
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API
    And I have a "full" authorised user with the key "cucumber"

    Given I have an "active" study called "Study A"
    And the UUID for the study "Study A" is "22222222-3333-4444-5555-000000000000"

    Given there is a 96 well "Cherrypicked" plate with a barcode of "1220012345855"

    Given I have a project called "Project A"
    And the UUID for the project "Project A" is "22222222-3333-4444-5555-000000000001"

    And the UUID of the next submission created will be "11111111-2222-3333-4444-555555555555"
    And the UUID of the next order created will be "11111111-2222-3333-4444-666666666666"

