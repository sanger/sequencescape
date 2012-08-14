@bait_libraries
Feature: Manage a list of bait libraries
  In order to allow easy editing of bait libraries
  I should be able to access an editing interface
  Only when logged in as an admin

  Scenario: The Administrator page should link to the bait library editor
    Given I am a "administrator" user logged in as "admin"
      And I am on the admin page
    Then I should see "Bait library management"
    When I follow "Bait library management"
    Then I should be on the bait library management page
      And I should see "Listing All Bait Libraries"
      And I should see "New Bait Library"
      And the bait library index page should look like:
        | Name                | Supplier | Target Species | Bait Library Type | Edit | Delete |
        | Human all exon 50MB | Agilent  | Human          | Standard          | Edit | Delete |
        | Mouse all exon      | Agilent  | Mouse          | Standard          | Edit | Delete |
        | Zebrafish ZV9       | Agilent  | Zebrafish      | Standard          | Edit | Delete |
        | Zebrafish ZV8       | Agilent  | Zebrafish      | Standard          | Edit | Delete |

  Scenario: Non-administrators should not see the bait library editor
    Given I am logged in as "user"
      And I go to the bait library management page
    Then I should not see "Listing All Bait Libraries"

  Scenario: Administrators should be able to edit bait libraries
    Given I am a "administrator" user logged in as "admin"
      And I go to the bait library management page
      And I follow "Edit Human all exon 50MB"
    Then I should see "Editing Bait Library"
    When I fill in "Name" with "Dragon all exon"
      And I select "Agilent" from "Supplier"
      And I fill in "Target species" with "Dracos"
      And I fill in "Supplier Identifier" with ""
      And I select "Custom - Pipeline" from "Bait library type"
      And I press "Update"
    Then I should see "Bait Library was successfully updated."
      And I should be on the bait library management page
      And I should see "Dragon all exon"
      And I should see "Dracos"
      And the supplier_identifier for "Dragon all exon" should be nil
      And I should see "Custom - Pipeline"
      And I should not see "Human all exon 50MB"

  Scenario: Administrators should be able to add and remove bait libraries
    Given I am a "administrator" user logged in as "admin"
      And I go to the bait library management page
      And I follow "New Bait Library"
    Then I should see "New Bait Library"
    When I fill in "Name" with "Centaur all exon"
      And I select "Agilent" from "Supplier"
      And I fill in "Target species" with "Centaur(Greek)"
      And I fill in "Supplier Identifier" with "8675309"
      And I select "Custom - Customer" from "Bait library type"
      And I press "Create"
    Then I should see "Bait Library was successfully created."
      And I should see "Centaur all exon"
      And I should see "Centaur(Greek)"
      And I should see "Custom - Customer"
      And I should see "8675309"
    When I follow "Delete Centaur all exon"
    Then I should see "Bait Library was successfully deleted."
      And I should not see "Centaur all exon"

  Scenario: Invalid attempts should fail cleanly
    Given I am a "administrator" user logged in as "admin"
      And I go to the bait library management page
      And I follow "New Bait Library"
      And I fill in "Name" with ""
      And I press "Create"
    Then I should see "2 errors prohibited this bait library from being saved"
      And I should see "Name can't be blank"
      And I should see "Target species can't be blank"
    When I go to the bait library management page
     And I follow "Edit Human all exon 50MB"
      And I fill in "Name" with ""
      And I select "Custom - Pipeline" from "Bait library type"
      And I press "Update"
    Then I should see "1 error prohibited this bait library from being saved"
      And I should see "Name can't be blank"
    When I go to the bait library management page
      Then I should be on the bait library management page
      And I should not see "Custom - Pipeline" within "#bait_library_list"
      And I should see "Human all exon 50MB"

  Scenario: Administrators should be able to view library types and suppliers
    Given I am an "administrator" user logged in as "admin"
      And I am on the bait library management page
    Then  I should see "Listing All Bait Library Types"
      And I should see "Listing All Bait Library Suppliers"
      And the bait library supplier index should look like:
        | Name    | Edit | Delete |
        | Agilent | Edit | Delete |
      And the bait library type index should look like:
        | Name              | Edit | Delete |
        | Standard          | Edit | Delete |
        | Custom - Pipeline | Edit | Delete |
        | Custom - Customer | Edit | Delete |

  Scenario: Administrators should be able to edit and create suppliers
    Given I am an "administrator" user logged in as "admin"
      And I am on the bait library management page
      And I follow "Edit Agilent"
    Then I should see "Editing Bait Library Supplier"
    When I fill in "Name" with "Other Supplier"
      And I press "Update"
    Then I should see "Supplier was successfully updated."
      And I should see "Other Supplier"
      And I should not see "Agilent"
    When I follow "New Bait Library Supplier"
    Then I should see "New Bait Library Supplier"
    When I fill in "Name" with "New Supplier"
      And I press "Create"
    Then I should see "Supplier was successfully created."
      And I should see "New Supplier"
    When I follow "Delete New Supplier"
    Then I should see "Supplier was successfully deleted."
      And I should not see "New Supplier"

  Scenario: Administrators should be able to edit and create types
    Given I am an "administrator" user logged in as "admin"
      And I am on the bait library management page
      And I follow "Edit Standard"
    Then I should see "Editing Bait Library Type"
    When I fill in "Name" with "Normal"
      And I press "Update"
    Then I should see "Bait Library Type was successfully updated."
      And I should see "Normal"
      And I should not see "Standard"
    When I follow "New Bait Library Type"
    Then I should see "New Bait Library Type"
    When I fill in "Name" with "Rare"
      And I press "Create"
    Then I should see "Bait Library Type was successfully created."
      And I should see "Rare"
    When I follow "Delete Rare"
    Then I should see "Bait Library Type was successfully deleted."
      And I should not see "Rare"

  Scenario: 'Deleting' bait libraries etc. should actually hide them
    Given I am an "administrator" user logged in as "admin"
      And I have a bait library called "Delete This"
      And I have a bait library type called "Defunct Type"
      And I have a supplier called "Gone Bankrupt Inc."
      And I go to the bait library management page
    Then I should see "Delete This"
      And I should see "Defunct Type"
      And I should see "Gone Bankrupt Inc."
    When I follow "Delete Delete This"
      And I follow "Delete Defunct Type"
      And I follow "Delete Gone Bankrupt Inc."
    Then I should not see "Delete This"
      And I should not see "Defunct Type"
      And I should not see "Gone Bankrupt Inc."
      And the "BaitLibrary" called "Delete This" should exist
      And the "BaitLibraryType" called "Defunct Type" should exist
      And the "BaitLibrary::Supplier" called "Gone Bankrupt Inc." should exist
    When I follow "Edit Human all exon 50MB"
    Then I should not see "Defunct Type"
      And I should not see "Gone Bankrupt Inc."
      And I should see "Custom - Customer"

  Scenario: I should not be able to delete in use bait library types etc.
    Given I am an "administrator" user logged in as "admin"
      And I have a bait library called "Dragon all exon"
      And the last bait library has type "Active Type"
      And the last bait library has supplier "Gone Bankrupt Inc."
      And I go to the bait library management page
    When I follow "Delete Active Type"
    Then I should see "Can not delete 'Active Type', bait library type is in use by 1 libraries." within "#message_error"
      And I should see "Active Type" within "#bait_library_types_list"
    When I follow "Delete Gone Bankrupt Inc."
    Then I should see "Can not delete 'Gone Bankrupt Inc.', supplier is in use by 1 libraries." within "#message_error"
      And I should see "Gone Bankrupt Inc."

  @javascript
  Scenario: I should not be able to select inactive libraries
    Given I am an "administrator" user logged in as "admin"
      And I have a bait library called "Delete This"
      And the last bait library is hidden
      And I am on the Submissions Inbox page
    When I follow "new Submission"
     And I select "Pulldown ISC - Single ended sequencing" from "submission_template_id"
     Then I should see "Human all exon 50MB"
     And I should not see "Delete This"

  @api @json @pulldown @submission @single-sign-on @new-api @barcode-service @pulldown_api
  Scenario: Invalid submission bait libraries are checked at creation
    Given all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"
    Given all HTTP requests to the API have the cookie "WTSISignOn" set to "I-am-authenticated"
    And the WTSI single sign-on service recognises "I-am-authenticated" as "John Smith"
    Given I am using the latest version of the API

    Given I have an "active" study called "Study A"
    And the UUID for the study "Study A" is "22222222-3333-4444-5555-000000000000"

    Given plate "1234567" with 3 samples in study "Study A" exists
    Given plate "1234567" has nonzero concentration results

    Given I have a project called "Testing submission creation"
    And the UUID for the project "Testing submission creation" is "22222222-3333-4444-5555-000000000001"
    And project "Testing submission creation" has enough quotas

    Given the UUID for the request type "Cherrypicking for Pulldown" is "99999999-1111-2222-3333-000000000000"
    And the UUID for the request type "Pulldown Multiplex Library Preparation" is "99999999-1111-2222-3333-000000000001"
    And the UUID for the request type "HiSeq Paired end sequencing" is "99999999-1111-2222-3333-000000000002"

    Given the UUID for the well "Well_1234567_1" is "44444444-2222-3333-4444-000000000001"
    And the UUID for the well "Well_1234567_2" is "44444444-2222-3333-4444-000000000002"
    And the UUID for the well "Well_1234567_3" is "44444444-2222-3333-4444-000000000003"

    Given I have a bait library called "Delete This"
    And the last bait library is hidden

    Given the UUID for the submission template "Pulldown ISC - Single ended sequencing" is "00000000-1111-2222-3333-444444444444"
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
             "read_length": 37,
             "fragment_size_required": {
               "from": 100,
               "to": 200
             },
             "bait_library": "Delete This"
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
    Then the submission with UUID "11111111-2222-3333-4444-555555555555" should not be ready
     And the submission with UUID "11111111-2222-3333-4444-555555555555" should have the error "Validation failed: Bait library is no longer available."
