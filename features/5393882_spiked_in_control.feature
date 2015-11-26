@spiked
Feature: Creating Spiked phiX
  Background:
    Given I am an "administrator" user logged in as "me"

    Given I have a sample tube called "Stock of phiX"
      And the "volume" of the asset called "Stock of phiX" is "200.0"

  Scenario: A member of the library creation team creates a "batch" of indexed phiX.
    Given I am on the asset creation page
    When I select "Library Tube" from "Type"
    And I fill in "Parent Asset" with "Stock of phiX"
    And I fill in "Name" with "indexed phiX"
    And I fill in "Concentration" with "17"
    And I fill in "Volume" with "100"
    And I fill in "vol." with "100"
    When I press "Create"
    Then I should see "Below are the assets which have been created"
    And I should see "indexed phiX"
    And I should see "print"

    And the "concentration" of the asset called "indexed phiX" should be "17.0"
    And the "volume" of the asset called "indexed phiX" should be "100.0"

    When I am on the show page for asset "indexed phiX"
    And I should see "LibraryTube"

  #Scenario: A member of the cluster formation team will create a new "batch" of Hybridization buffer spiked with phiX.
    #Given I am logged in as "me"
    #And I have a library tube of stuff called "indexed phiX"
    #And the "volume" of the asset called "indexed phiX" is "100"

    Given I am on the asset creation page
    When I select "Hybridization Buffer Spiked" from "Type"
    And I fill in "Name" with "hbs"
    And I fill in "Parent Asset" with "indexed phiX"
    And I fill in "vol." with "40"
    And I fill in "Volume" with "240"
    When I press "Create"
    Then I should see "hbs"
    Then I should see "print"

    When I am on the show page for asset "hbs"
    And I should see "SpikedBuffer"

    # Checking new volumes
    Then the "volume" of the asset called "indexed phiX" should be "60.0"
    Then the "volume" of the asset called "hbs" should be "240.0"
    Then the "volume" of the parent asset of the asset called "hbs" should be "40.0"


    #Scenario: A member of the cluster formation team will create a number of aliquots from the spiked Hybridization buffer
    Given I am on the asset creation page
    When I select "Hybridization Buffer Spiked" from "Type"
    And I fill in "Name" with "Aliquot"
    And I fill in "Parent Asset" with "hbs"
    And I fill in "vol." with "24"
    And I fill in "Count" with "5"

    When I press "Create"
    Then I should see "print"
    And I should see "Aliquot #1"
    And I should see "Aliquot #2"
    And I should see "Aliquot #3"
    And I should see "Aliquot #4"
    And I should see "Aliquot #5"

    # Checking that stuff which shouldn't change are still the same
    Then the "volume" of the asset called "indexed phiX" should be "60.0"

    # Checking that stuff wich should have had.
    Then the "volume" of the asset called "hbs" should be "120.0"
    Then the "volume" of the parent asset of the asset called "hbs" should be "20.0"
    Then the "volume" of the asset called "Aliquot #1" should be "24.0"
    Then the "volume" of the index asset of the asset called "Aliquot #5" should be "4.0"

  Scenario: The cluster formation team member create a batch that will use spiked in controls.
    Given I have a batch with 8 requests for the "Cluster formation PE (spiked in controls)" pipeline
    And  I have a hybridization spiked buffer called "Aliquot #1"
    And the "barcode" of the asset called "Aliquot #1" is "1"

    When I on batch page
    And I follow "Add Spiked in Control"
    And I fill in "Barcode" with the human barcode "NT1x"
    And I check "sample 1 checkbox"
    And I check "sample 2 checkbox"
    And I check "sample 3 checkbox"
    And I check "sample 4 checkbox"
    And I check "sample 5 checkbox"
    And I check "sample 6 checkbox"
    And I check "sample 7 checkbox"
    And I check "sample 8 checkbox"
    And I press "Next step"
    When I follow "Lane" within ".row0"
    Then I should see "Spiked Buffer"

  # TODO: use factories for controls and batch
  @npg @xml
  Scenario: Create a batch and check the xm
    # create control
    Given I am on the asset creation page
    When I select "Library Tube" from "Type"
    And I fill in "Name" with "indexed phiX"
    And I fill in "Concentration" with "17"
    And I fill in "Volume" with "100"
    And I fill in "Parent Asset" with "Stock of phiX"
    And I fill in "vol." with "100"
    When I press "Create"
    Then I should see "Below are the assets which have been created"
    And I should see "indexed phiX"
    And I should see "print"

    And the "concentration" of the asset called "indexed phiX" should be "17.0"
    And the "volume" of the asset called "indexed phiX" should be "100.0"

    When I am on the show page for asset "indexed phiX"
    And I should see "LibraryTube"

#create Hybridization Buffer Spiked (Stock)
    Given I am on the asset creation page
    When I select "Hybridization Buffer Spiked" from "Type"
    And I fill in "Name" with "hbs"
    And I fill in "Parent Asset" with "indexed phiX "
    And I fill in "vol." with "40"
    And I fill in "Volume" with "240"
    When I press "Create"
    Then I should see "hbs"
    Then I should see "print"

    #create the aliquots

    Given I am on the asset creation page
    When I select "Hybridization Buffer Spiked" from "Type"
    And I fill in "Name" with "Aliquot"
    And I fill in "Parent Asset" with "hbs"
    And I fill in "vol." with "24"
    And I fill in "Count" with "2"
    When I press "Create"
    Then I should see "print"
    And I should see "Aliquot #1"
    And I should see "Aliquot #2"

    Given the "barcode" of the asset called "Aliquot #1" is "1"

    Given I have a batch with 8 requests for the "Cluster formation PE (spiked in controls)" pipeline
    When I on batch page
    And I follow "Add Spiked in Control"
    And I fill in "Barcode" with the human barcode "NT1x"
    And I uncheck "sample 1 checkbox"
    And I check "sample 2 checkbox"
    And I uncheck "sample 3 checkbox"
    And I uncheck "sample 4 checkbox"
    And I uncheck "sample 5 checkbox"
    And I uncheck "sample 6 checkbox"
    And I uncheck "sample 7 checkbox"
    And I uncheck "sample 8 checkbox"
    And I press "Next step"

    When I get the XML for the last batch
    Then ignoring "library|\bid|tag_id|sample_id|consent_withdrawn|tag_group_id" the XML response should be:
  """
<?xml version="1.0" encoding="UTF-8"?>
<batch>
  <id>35</id>
  <status>started</status>
  <lanes>
    <lane position="1" priority="0">
      <library name="Asset 1" request_id="273" project_id="35" id="784" study_id="35" sample_id="273" qc_state=""/>
    </lane>
    <lane position="2" priority="0">
      <library name="Asset 2" request_id="274" project_id="35" id="785" study_id="35" sample_id="274" qc_state=""/>
      <hyb_buffer id="780">
        <control name="indexed phiX" id="781"/>
        <sample project_id="" study_id="" sample_id="5">
          <tag tag_id="19">
            <index>888</index>
            <expected_sequence>ACAACGCAAT</expected_sequence>
            <tag_group_id>6</tag_group_id>
          </tag>
        </sample>
      </hyb_buffer>
    </lane>
    <lane position="3" priority="0">
      <library name="Asset 3" request_id="275" project_id="35" id="786" study_id="35" sample_id="275" qc_state=""/>
    </lane>
    <lane position="4" priority="0">
      <library name="Asset 4" request_id="276" project_id="35" id="787" study_id="35" sample_id="276" qc_state=""/>
    </lane>
    <lane position="5" priority="0">
      <library name="Asset 5" request_id="277" project_id="35" id="788" study_id="35" sample_id="277" qc_state=""/>
    </lane>
    <lane position="6" priority="0">
      <library name="Asset 6" request_id="278" project_id="35" id="789" study_id="35" sample_id="278" qc_state=""/>
    </lane>
    <lane position="7" priority="0">
      <library name="Asset 7" request_id="279" project_id="35" id="790" study_id="35" sample_id="279" qc_state=""/>
    </lane>
    <lane position="8" priority="0">
      <library name="Asset 8" request_id="280" project_id="35" id="791" study_id="35" sample_id="280" qc_state=""/>
    </lane>
  </lanes>
</batch>

    """
