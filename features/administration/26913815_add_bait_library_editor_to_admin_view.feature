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
      And I am on the admin page
      And I follow "Bait library management"
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

  Scenario: Administrators should be able to add bait libraries
    Given I am a "administrator" user logged in as "admin"
      And I am on the admin page
      And I follow "Bait library management"
      And I follow "New Bait Library"
      And I fill in "Name" with "Centaur all exon"
      And I select "Agilent" from "Supplier"
      And I fill in "Target species" with "Centaur(Greek)"
      And I select "Custom - Customer" from "Bait library type"
      And I press "Create"
    Then I should see "Bait Library was successfully created."
      And I should see "Centaur all exon"
      And I should see "Centaur(Greek)"
      And I should see "Custom - Customer"
      
  Scenario: Invalid attempts should fail cleanly
    Given I am a "administrator" user logged in as "admin"
      And I am on the admin page
      And I follow "Bait library management"
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
      And I should not see "Custom - Pipeline"
      And I should see "Human all exon 50MB"