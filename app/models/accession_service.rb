# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015,2016 Genome Research Ltd.

class AccessionService
  # We overide this in testing to do a bit of evesdropping
  class_attribute :rest_client_class
  self.rest_client_class = RestClient::Resource

  AccessionServiceError = Class.new(StandardError)
  NumberNotRequired     = Class.new(AccessionServiceError)
  NumberNotGenerated    = Class.new(AccessionServiceError)

  CenterName = 'SC'.freeze # TODO: [xxx] use confing file
  Protect = 'protect'.freeze
  Hold = 'hold'.freeze

  def provider; end

  class AccessionedFile < File
    # This class provides an original_filename method
    # which RestClient can use to define the remote filename
    attr_accessor :original_filename
  end

  # When samples belong to multiple studies, the submission service with the highest priority will be selected
  class_attribute :priority, instance_writer: false
  # When true, allows the accessioning of samples prior to accessioning of the study
  class_attribute :no_study_accession_needed, instance_writer: false
  # Indicates that the class reflects a real accessioning service. Set to false for dummy services. This allow
  # scripts like the accessioning cron to break out prematurely for dummy services
  class_attribute :operational, instance_writer: false

  self.priority = 0
  self.no_study_accession_needed = false
  self.operational = false

  def submit(user, *accessionables)
    ActiveRecord::Base.transaction do
      submission = Accessionable::Submission.new(self, user, *accessionables)

      errors = submission.all_accessionables.map(&:errors).flatten

      raise AccessionServiceError, errors.join("\n") unless errors.empty?

      files = [] # maybe not necessary, but just to be sure that the tempfile still exists when they are sent
      begin
        xml_result = post_files(submission.all_accessionables.map do |acc|
            file = Tempfile.open("#{acc.schema_type}_file")
            files << file
            file.puts(acc.xml)
            file.open # reopen for read

            Rails::logger.debug { file.each_line.to_a.join("\n") }

            { name: acc.schema_type.upcase, local_name: file.path, remote_name: acc.file_name }
                                end
         )
        Rails::logger.debug { xml_result }
        raise AccessionServiceError, "EBI Server Error. Couldnt get accession number: #{xml_result}" if xml_result =~ /(Server error|Auth required|Login failed)/

        xmldoc  = Document.new(xml_result)
        success = xmldoc.root.attributes['success']
        accession_numbers = []
        # for some reasons, ebi doesn't give us back a accession number for the submission if it's a MODIFY action
        # therefore, we should be ready to get one or not
        number_generated = true
        if success == 'true'
          # extract and update accession numbers
          accession_number = submission.all_accessionables.each do |acc|
            accession_number = acc.extract_accession_number(xmldoc)
            if accession_number
              acc.update_accession_number!(user, accession_number)
              accession_numbers << accession_number
            else
              # error only, if one of the expected accessionable didn't get a AN
              # We don't care about the submission
              number_generated = false if accessionables.include?(acc)
            end
            ae_an = acc.extract_array_express_accession_number(xmldoc)
            acc.update_array_express_accession_number!(ae_an) if ae_an
          end

          raise NumberNotGenerated, 'Service gave no numbers back' unless number_generated

        elsif success == 'false'
          errors = xmldoc.root.elements.to_a('//ERROR').map(&:text)
          raise AccessionServiceError, "Could not get accession number. Error in submitted data: #{$!} #{errors.map { |e| "\n  - #{e}" }}"
        else
          raise AccessionServiceError, "Could not get accession number. Error in submitted data: #{$!}"
        end
      ensure
        files.each { |f| f.close } # not really necessary but recommended
      end

      return accessionables.map(&:accession_number)
    end
  end

  def submit_sample_for_user(sample, user)
    # raise NumberNotRequired, 'Does not require an accession number' unless sample.studies.first.ena_accession_required?

    ebi_accession_number = sample.sample_metadata.sample_ebi_accession_number
    # raise NumberNotGenerated, 'No need to' if not ebi_accession_number.blank? and not /ERS/.match(ebi_accession_number)

    submit(user, Accessionable::Sample.new(sample))
  end

  def submit_study_for_user(study, user)
    raise NumberNotRequired, 'An accession number is not required for this study' unless study.ena_accession_required?

    # TODO: check error
    # raise AccessionServiceError, "Cannot generate accession number: #{ sampledata[:error] }" if sampledata[:error]

    ebi_accession_number = study.study_metadata.study_ebi_accession_number
    # raise NumberNotGenerated, 'No need to' if not ebi_accession_number.blank? and not /ER/.match(ebi_accession_number)

    submit(user, Accessionable::Study.new(study))
  end

  def submit_dac_for_user(_study, _user)
    raise NumberNotRequired, 'No need to'
  end

  def accession_study_xml(study)
    Accessionable::Study.new(study).xml
  end

  def accession_sample_xml(sample)
    Accessionable::Sample.new(sample).xml
  end

  def accession_policy_xml(study)
    policy = Accessionable::Policy.new(study)
    policy.xml
  end

  def accession_dac_xml(study)
    Accessionable::Dac.new(study).xml
  end

  def sample_visibility(_sample)
    Protect
  end

  def study_visibility(_study)
    Protect
  end

  def policy_visibility(_study)
    Protect
  end

  def dac_visibility(_study)
    Protect
  end

  def private?
    false
  end

private

  def accession_study_set_xml_quarantine(study, studydata)
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.STUDY_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
      xml.STUDY(alias: studydata[:alias], accession: study.study_metadata.study_ebi_accession_number) {
        xml.DESCRIPTOR {
          xml.STUDY_TITLE         studydata[:study_title]
          xml.STUDY_DESCRIPTION   studydata[:description]
          xml.CENTER_PROJECT_NAME studydata[:center_study_name]
          xml.CENTER_NAME         studydata[:center_name]
          xml.STUDY_ABSTRACT      studydata[:study_abstract]

          xml.PROJECT_ID(studydata[:study_id] || '0')
          study_type = studydata[:existing_study_type]
          if StudyType.include?(study_type)
            xml.STUDY_TYPE(existing_study_type: study_type)
          else
            xml.STUDY_TYPE(existing_study_type: Study::Other_type, new_study_type: study_type)
          end
        }
      }
    }
    xml.target!
  end

  def accession_sample_set_xml_quarantine(sample, sampledata)
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.SAMPLE_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
      xml.SAMPLE(alias: sampledata[:alias], accession: sample.sample_metadata.sample_ebi_accession_number) {
        xml.SAMPLE_NAME {
          xml.COMMON_NAME  sampledata[:sample_common_name]
          xml.TAXON_ID     sampledata[:taxon_id]
        }
        xml.SAMPLE_ATTRIBUTES {
          sampledata[:tags].each do |tagpair|
            xml.SAMPLE_ATTRIBUTE {
              xml.TAG   tagpair[:tag]
              xml.VALUE tagpair[:value]
            }
          end
        } unless sampledata[:tags].blank?

        xml.SAMPLE_LINKS {} unless sampledata[:links].blank?
      }
    }
    xml.target!
  end

  def accession_submission_xml(submission, accession_number)
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.SUBMISSION(
      'xmlns:xsi'      => 'http://www.w3.org/2001/XMLSchema-instance',
      :center_name     => submission[:center_name],
      :broker_name     => submission[:broker],
      :alias           => submission[:submission_id],
      :submission_date => submission[:submission_date]
    ) {
      xml.CONTACTS {
        xml.CONTACT(
          inform_on_error: submission[:contact_inform_on_error],
          inform_on_status: submission[:contact_inform_on_status],
          name: submission[:name]
        )
      }
      xml.ACTIONS {
        xml.ACTION {
          if accession_number.blank?
            xml.ADD(source: submission[:source], schema: submission[:schema])
          else
            xml.MODIFY(source: submission[:source], target: '')
          end
        }
        xml.ACTION {
          if submission[:hold] == AccessionService::Protect
            xml.PROTECT
          else
            xml.HOLD
          end
        }
      }
    }
    xml.target!
  end

  require 'rexml/document'
  # require 'curb'
  include REXML

  def accession_options
    raise NotImplemented, 'abstract method'
  end

  def rest_client_resource
    rest_client_class.new(configatron.accession.url!, accession_options)
  end

  def post_files(file_params)
    rc = rest_client_resource

    if configatron.disable_web_proxy == true
      RestClient.proxy = ''
    elsif not configatron.proxy.blank?
      RestClient.proxy = configatron.proxy
      # UA required to get through Sanger proxy
      # Although currently this UA is actually being set elsewhere in the
      # code as RestClient doesn't pass this header to the proxy.
      rc.options[:headers] = { user_agent: "Sequencescape Accession Client (#{Rails.env})" }
    end

    payload = file_params.each_with_object({}) do |param, hash|
      hash[param[:name]] = AccessionedFile.open(param[:local_name]).tap { |f| f.original_filename = param[:remote_name] }
    end

    response = rc.post(payload)
    case response.code
    when (200...300) # success
      return response.body.to_s
    when (400...600)
      Rails.logger.warn($!)
      $! = nil
      raise AccessionServiceError
    else
    return ''
    end
  rescue StandardError => exception
    raise AccessionServiceError, "Could not get accession number. EBI may be down or invalid data submitted: #{$!}"
  end
end
