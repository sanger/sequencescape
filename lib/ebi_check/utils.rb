# frozen_string_literal: true

module EbiCheck
  module Utils
    # Study XPaths
    XPATH_STUDY_TITLE = '//STUDY_TITLE'
    XPATH_STUDY_DESCRIPTION = '//STUDY_DESCRIPTION'
    XPATH_CENTER_PROJECT_NAME = '//CENTER_PROJECT_NAME'
    XPATH_STUDY_ABSTRACT = '//STUDY_ABSTRACT'
    XPATH_EXISTING_STUDY_TYPE = '//STUDY_TYPE/@existing_study_type'
    XPATH_NEW_STUDY_TYPE = '//STUDY_TYPE/@new_study_type'

    # Sample XPaths
    XPATH_SCIENTIFIC_NAME = '//SAMPLE/SAMPLE_NAME/SCIENTIFIC_NAME'
    XPATH_COMMON_NAME = '//SAMPLE/SAMPLE_NAME/COMMON_NAME'
    XPATH_SAMPLE_TITLE = '//SAMPLE/TITLE'
    XPATH_SAMPLE_ATTRIBUTE = '//SAMPLE/SAMPLE_ATTRIBUTES/SAMPLE_ATTRIBUTE'
    XPATH_TAXON_ID = '//SAMPLE/SAMPLE_NAME/TAXON_ID'
    XPATH_VALUE = 'VALUE'
    XPATH_TAG = 'TAG'

    class << self
      def extract_study_fields(xml)
        doc = Nokogiri::XML(xml)
        {
          title: doc.at_xpath(XPATH_STUDY_TITLE)&.text,
          description: doc.at_xpath(XPATH_STUDY_DESCRIPTION)&.text,
          project_name: doc.at_xpath(XPATH_CENTER_PROJECT_NAME)&.text,
          abstract: doc.at_xpath(XPATH_STUDY_ABSTRACT)&.text,
          existing_study_type: doc.at_xpath(XPATH_EXISTING_STUDY_TYPE)&.text,
          new_study_type: doc.at_xpath(XPATH_NEW_STUDY_TYPE)&.text
        }
      end

      def extract_sample_fields(xml)
        doc = Nokogiri::XML(xml)
        result = extract_sample_basic_fields(doc)
        result.merge!(extract_sample_attributes_fields(doc))
        result
      end

      private

      def extract_sample_basic_fields(doc)
        scientific_name = doc.at_xpath(XPATH_SCIENTIFIC_NAME)&.text
        common_name = scientific_name || doc.at_xpath(XPATH_COMMON_NAME)&.text
        {
          title: doc.at_xpath(XPATH_SAMPLE_TITLE)&.text,
          taxon_id: doc.at_xpath(XPATH_TAXON_ID)&.text,
          common_name: common_name
        }
      end

      def extract_sample_attributes_fields(doc)
        result = {}
        doc.xpath(XPATH_SAMPLE_ATTRIBUTE).each do |attr|
          tag = attr.at_xpath(XPATH_TAG)&.text
          tag = tag.downcase
          value = attr.at_xpath(XPATH_VALUE)&.text
          result[tag.to_sym] = value
        end
        result
      end
    end
  end
end
