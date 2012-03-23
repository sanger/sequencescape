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
      And I select "Custom - Pipeline" from "Bait library type"
      And I press "Update"
    Then I should see "Bait Library was successfully updated." 
      And I should be on the bait library management page
      And I should see "Dragon all exon"
      And I should see "Dracos"
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
      And I select "Custom - Customer" from "Bait library type"
      And I press "Create"
    Then I should see "Bait Library was successfully created."
      And I should see "Centaur all exon"
      And I should see "Centaur(Greek)"
      And I should see "Custom - Customer"
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