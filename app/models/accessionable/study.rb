#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
module Accessionable
  class Study < Base
    attr_reader :study_title, :description, :center_study_name, :study_abstract, :existing_study_type, :tags, :related_studies
    def initialize(study)
      @study = study
      data = {}

      study_title = study.study_metadata.study_study_title
      @name = study_title.blank? ? '' : study_title.gsub(/[^a-z\d]/i, '_')

      study_type = study.study_metadata.study_type.name
      @existing_study_type = study_type # the study type if validated is exactly the one submission need

      @study_title = @name
      @center_study_name = @study_title

      pid = study.study_metadata.study_project_id
      @study_id = pid.blank? ? '0' : pid

      study_abstract = study.study_metadata.study_abstract
      @study_abstract = study_abstract unless study_abstract.blank?

      study_desc = study.study_metadata.study_description
      @description = study_desc unless study_desc.blank?

      @tags = []
      @tags << Tag.new(self.label_scope, "ArrayExpress", nil) if study.for_array_express?
      super(study.study_metadata.study_ebi_accession_number)

      @related_studies = []
      study.study_relations.each do |r|
        @related_studies << RelatedStudy.new(r.related_study, r.name)
      end
      study.reversed_study_relations.each do |r|
        rs=RelatedStudy.new(r.study, r.reversed_name)
        @related_studies << rs if rs.to_send?
      end
    end

    def errors
      error_list = []
      error_list + @related_studies.map(&:errors)
    end

    def xml
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.STUDY_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
        xml.STUDY(:alias => self.alias, :accession => self.accession_number) {
        xml.DESCRIPTOR {
        xml.STUDY_TITLE         self.study_title
        xml.STUDY_DESCRIPTION   self.description
        xml.CENTER_PROJECT_NAME self.center_study_name
        xml.CENTER_NAME         self.center_name
        xml.STUDY_ABSTRACT      self.study_abstract

        xml.PROJECT_ID(self.accessionable_id || "0")
        study_type = self.existing_study_type
        if StudyType.include?(study_type)
          xml.STUDY_TYPE(:existing_study_type => study_type)
        else
          xml.STUDY_TYPE(:existing_study_type => ::Study::Other_type , :new_study_type => study_type)
        end

        xml.RELATED_STUDIES {
          self.related_studies.each do |study|
            study.build(xml)
          end
        }   unless self.related_studies.blank?
      }
      xml.STUDY_ATTRIBUTES {
        self.tags.each do |tag|
        xml.STUDY_ATTRIBUTE {
          tag.build(xml)
        }
        end
      } unless self.tags.blank?
      }
      }
      return xml.target!
    end

    def accessionable_id
      @study.id
    end

    def protect?(service)
      service.study_visibility(@study) == AccessionService::Protect
    end

    def update_accession_number!(user, accession_number)
      @accession_number = accession_number
      add_updated_event(user, "Study #{@study.id}", @study) if @accession_number
      @study.study_metadata.study_ebi_accession_number = accession_number
      @study.save!
    end

    def update_array_express_accession_number!(number)
      @study.study_metadata.array_express_accession_number = number
      @study.save!
    end

  end
  private
  class  RelatedStudy
    def initialize(study, role, primary = false)
      @study = study
      @role = role
      @primary = primary
    end

    # return if the Link would need to be send to the accession service
    def to_send?
      db_label.present?
    end

    def errors
      [].tap do |errs|
        errs << "Accession number needed for related study #{@study.name}" if @study.ebi_accession_number.blank?
      end
    end

    def build(xml)
      return if db_label.blank?
      xml.RELATED_STUDY {
        xml.RELATED_LINK {
          xml.DB db_label
          xml.ID @study.ebi_accession_number
      }
        xml.IS_PRIMARY @primary
      }
    end

    def db_label
      I18n.t("metadata.study.metadata.#{ @role }.ebi_db", :default => "")
    end
  end
end
