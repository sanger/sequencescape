# rake features FEATURE=features/plain/samples/xml_interface.feature
@sample @xml
Feature: The XML interface to the samples
  Background:
    Given the sample named "testing_the_xml_interface" exists
    And the sample "testing_the_xml_interface" has the common name "John's Gene"

  Scenario: Retrieving the XML for a specific sample
    When I get the XML for the sample "testing_the_xml_interface"
    Then ignoring "id" the XML response should be:
      """
      <?xml version="1.0" encoding="UTF-8"?>
      <sample api_version="0.6">
        <id>1</id>
        <name>testing_the_xml_interface</name>
        <consent_withdrawn>false</consent_withdrawn>
        <properties>
          <property><name>Consent withdrawn</name><value>false</value></property>
          <property><name>Date of consent withdrawn</name><value/></property>
          <property><name>Identifier of the user that withdrew consent</name><value/></property>
          <property><name>Cohort</name><value/></property>
          <property><name>Common Name</name><value>John's Gene</value></property>
          <property><name>Concentration</name><value/></property>
          <property><name>Concentration determind by</name><value/></property>
          <property><name>Country of origin</name><value/></property>
          <property><name>DNA source</name><value/></property>
          <property><name>Date of sample collection</name><value/></property>
          <property><name>Date of sample extraction</name><value/></property>
          <property><name>ENA Sample Accession Number</name><value/></property>
          <property><name>Ethnicity</name><value/></property>
          <property><name>Father</name><value/></property>
          <property><name>GC content</name><value/></property>
          <property><name>Gender</name><value/></property>
          <property><name>Geographical region</name><value/></property>
          <property><name>Is re-submitted?</name><value/></property>
          <property><name>Mother</name><value/></property>
          <property><name>Organism</name><value/></property>
          <property><name>Volume (&#181;l)</name><value/></property>
          <property><name>Taxon ID</name><value/></property>
          <property><name>Public Name</name><value/></property>
          <property><name>Purification method</name><value/></property>
          <property><name>Reference Genome</name><value/></property>
          <property><name>Replicate</name><value/></property>
          <property><name>Sample Description</name><value/></property>
          <property><name>Sample Visibility</name><value/></property>
          <property><name>Sample extraction method</name><value/></property>
          <property><name>Sample purified</name><value/></property>
          <property><name>Sample storage conditions</name><value/></property>
          <property><name>Sample type</name><value/></property>
          <property><name>Sibling</name><value/></property>
          <property><name>Strain</name><value/></property>
          <property><name>Genome Size</name><value/></property>
          <property><name>Genotype</name><value></value></property>
          <property><name>Phenotype</name><value></value></property>
          <property><name>Age</name><value></value></property>
          <property><name>Developmental Stage</name><value></value></property>
          <property><name>Cell Type</name><value></value></property>
          <property><name>Subject</name><value></value></property>
          <property><name>Disease</name><value></value></property>
          <property><name>Disease State</name><value></value></property>
          <property><name>Treatment</name><value></value></property>
          <property><name>Compound</name><value></value></property>
          <property><name>Dose</name><value></value></property>
          <property><name>Immunoprecipitate</name><value></value></property>
          <property><name>Growth Condition</name><value></value></property>
          <property><name>RNAi</name><value></value></property>
          <property><name>Organism Part</name><value></value></property>
          <property><name>Time Point</name><value></value></property>
          <property><name>Donor Id</name><value></value></property>
          <property><name>Collected By</name><value/></property>
        </properties>
      </sample>
      """
