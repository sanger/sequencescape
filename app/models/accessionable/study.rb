# frozen_string_literal: true
# Handles submission of {Study} information to the EGA or ENA
# A study gathers together multiple {Accessionable::Sample samples} and essentially
# describes why they are being sequenced. It should have a 1 to 1 mapping with Sequencescape
# {Study studies}.
# A study can either be open (ENA) or managed (EGA) which determines which {AccessionService} it
# uses.
module Accessionable
  class Study < Base
    attr_reader :study_title, :description, :center_study_name, :study_abstract, :existing_study_type, :tags

    # rubocop:todo Metrics/MethodLength
    def initialize(study) # rubocop:todo Metrics/AbcSize
      @study = study
      data = {}

      study_title = study.study_metadata.study_study_title
      @name = study_title.blank? ? '' : study_title.gsub(/[^a-z\d]/i, '_')

      study_type = study.study_metadata.study_type.name
      @existing_study_type = study_type # the study type if validated is exactly the one submission need

      @study_title = @name
      @center_study_name = @study_title

      pid = study.study_metadata.study_project_id
      @study_id = pid.presence || '0'

      study_abstract = study.study_metadata.study_abstract
      @study_abstract = study_abstract if study_abstract.present?

      study_desc = study.study_metadata.study_description
      @description = study_desc if study_desc.present?

      @tags = []
      @tags << Tag.new(label_scope, 'ArrayExpress', nil) if study.for_array_express?
      super(study.study_metadata.study_ebi_accession_number)
    end

    # rubocop:enable Metrics/MethodLength

    def errors
      error_list = []
    end

    # rubocop:todo Metrics/MethodLength
    def xml # rubocop:todo Metrics/AbcSize
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.STUDY_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') do
        xml.STUDY(alias: self.alias, accession: accession_number) do
          xml.DESCRIPTOR do
            xml.STUDY_TITLE study_title
            xml.STUDY_DESCRIPTION description
            xml.CENTER_PROJECT_NAME center_study_name
            xml.CENTER_NAME center_name
            xml.STUDY_ABSTRACT study_abstract

            xml.PROJECT_ID(accessionable_id || '0')
            study_type = existing_study_type
            if StudyType.include?(study_type)
              xml.STUDY_TYPE(existing_study_type: study_type)
            else
              xml.STUDY_TYPE(existing_study_type: ::Study::OTHER_TYPE, new_study_type: study_type)
            end
          end
          xml.STUDY_ATTRIBUTES { tags.each { |tag| xml.STUDY_ATTRIBUTE { tag.build(xml) } } } if tags.present?
        end
      end
      xml.target!
    end

    # rubocop:enable Metrics/MethodLength

    def accessionable_id
      @study.id
    end

    def protect?(service)
      service.study_visibility(@study) == AccessionService::PROTECT
    end

    def update_accession_number!(user, accession_number)
      @accession_number = accession_number
      @study.study_metadata.study_ebi_accession_number = accession_number
      @study.save!
      @study.events.assigned_accession_number!('study', accession_number, user)
    end

    def update_array_express_accession_number!(number)
      @study.study_metadata.array_express_accession_number = number
      @study.save!
    end
  end
end
