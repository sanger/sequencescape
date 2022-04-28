@spiked
Feature: Creating Spiked phiX
  Background:
    Given I am an "administrator" user logged in as "me"

    Given I have a phiX tube called "Stock of phiX"
      And the "volume" of the asset called "Stock of phiX" is "200.0"

  # TODO: use factories for controls and batch
  @npg @xml
  Scenario: Create a batch and check the xml
    And  I have a hybridization spiked buffer called "Aliquot #1"
    And the barcode for the asset "Aliquot #1" is "NP1G"

    Given I have a batch with 8 requests for the "Cluster formation PE (spiked in controls)" pipeline
    When I on batch page
    And I follow "Add Spiked in Control"
    And I fill in "Barcode" with the human barcode "NP1G"
    And I uncheck "sample-1-checkbox"
    And I check "sample-2-checkbox"
    And I uncheck "sample-3-checkbox"
    And I uncheck "sample-4-checkbox"
    And I uncheck "sample-5-checkbox"
    And I uncheck "sample-6-checkbox"
    And I uncheck "sample-7-checkbox"
    And I uncheck "sample-8-checkbox"
    And I press "Next step"
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
