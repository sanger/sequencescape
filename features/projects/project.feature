@project
Feature: Project management

 Scenario: Create a Next-gen sequencing project as a non-administrator
   Given I am a "manager" user logged in as "user"

   When I follow "Create Project"
   Then I should see "Projects New"
   And I should not see "External funding source"
   And I should not see "Sequencing Project Manager"
   And I should not see "Sequencing budget division"
   And I should not see "Sequencing budget cost centre"

   When I fill in the field labeled "Name" with "Test project"
   And I fill in the field labeled "Project cost code" with "ABC"
   And I fill in the field labeled "Funding comments" with "Internal"
   And I fill in the field labeled "Collaborators" with "no collaborators"
   And I press "Create"
   Then I should see "Your project has been created"
   And I should see "no collaborators"
   And I should see "ABC"

 Scenario: Create a Next-gen sequencing project as an administrator
   Given I am a "administrator" user logged in as "user"
   When I follow "Create Project"
   Then I should see "Projects New"
   When I fill in the field labeled "Name" with "Test project"
   And I fill in the field labeled "Project cost code" with "ABC"
   And I fill in the field labeled "Funding comments" with "Internal"
   And I fill in the field labeled "Collaborators" with "no collaborators"
   And I fill in the field labeled "External funding source" with "no funding source"
   And I select "Unallocated" from "Sequencing Project Manager"
   And I select "Unallocated" from "Sequencing budget division"
   And I select "Internal" from "Project funding model"
   And I press "Create"
   Then I should see "Your project has been created"
   And I should see the project information:
     |Project cost code:             | ABC               |
     |Sequencing budget division:    | Unallocated       |
     |Sequencing budget cost centre: | Not specified     |
     |Project funding model:         | Internal          |
     |Funding comments:              | Internal          |
     |Collaborators:                 | no collaborators  |
     |Sequencing Project Manager:    | Unallocated       |
     |External funding source:       | no funding source |
     |Genotyping committee Tracking ID:| Not specified   |

 Scenario Outline: Create a Microarray genotyping project
   Given I am a "<user type>" user logged in as "user"

   And I am on the homepage

   When I follow "Create Project"
   Then I should see "Projects New"
   When I fill in the field labeled "Name" with "Test project"
   And I fill in the field labeled "Project cost code" with "ABC"
   And I fill in the field labeled "Genotyping committee Tracking ID" with "12345"
   When I press "Create"
   Then I should see "Your project has been created"
   And I should see "12345"
   And I should see "ABC"

   Examples:
     |user type    |
     |administrator|
     |manager      |
