class AccessionService
  AccessionServiceError = Class.new(StandardError)
  NumberNotRequired     = Class.new(AccessionServiceError)
  NumberNotGenerated    = Class.new(AccessionServiceError)

  CenterName = 'SC'.freeze # TODO [xxx] use confing file
  Protect = "protect".freeze
  Hold = "hold".freeze

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

            Rails::logger.debug { file.lines.to_a.join("\n") }

            {:name => acc.schema_type.upcase, :local_name => file.path, :remote_name => acc.file_name }
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
          #extract and update accession numbers
          accession_number = submission.all_accessionables.each do |acc|
            accession_number       = acc.extract_accession_number(xmldoc)
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
          errors = xmldoc.root.elements.to_a("//ERROR").map(&:text)
          raise AccessionServiceError, "Could not get accession number. Error in submitted data: #{$!} #{ errors.map { |e| "\n  - #{e}"} }"
        else
          raise AccessionServiceError,  "Could not get accession number. Error in submitted data: #{$!}"
        end
      ensure
        files.each { |f| f.close } # not really necessary but recommended
      end

      return accessionables.map(&:accession_number)
    end
  end

  def submit_sample_for_user(sample, user)
    raise NumberNotRequired, 'Does not require an accession number' unless sample.studies.first.ena_accession_required?

    ebi_accession_number = sample.sample_metadata.sample_ebi_accession_number
    #raise NumberNotGenerated, 'No need to' if not ebi_accession_number.blank? and not /ERS/.match(ebi_accession_number)

    submit(user,  Accessionable::Sample.new(sample))
  end

  def submit_study_for_user(study, user)
    raise NumberNotRequired, 'Does not require an accession_number' unless study.ena_accession_required?

    #TODO check error
    #raise AccessionServiceError, "Cannot generate accession number: #{ sampledata[:error] }" if sampledata[:error]


    ebi_accession_number = study.study_metadata.study_ebi_accession_number
    #raise NumberNotGenerated, 'No need to' if not ebi_accession_number.blank? and not /ER/.match(ebi_accession_number)

    return submit(user, Accessionable::Study.new(study))
  end

  def submit_dac_for_user(study, user)
    raise NumberNotRequired, "No need to"
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

  def sample_visibility(sample)
    Protect
  end

  def study_visibility(study)
    Protect
  end

  def policy_visibility(study)
    Protect
  end

  def dac_visibility(study)
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
      xml.STUDY(:alias => studydata[:alias], :accession => study.study_metadata.study_ebi_accession_number) {
        xml.DESCRIPTOR {
          xml.STUDY_TITLE         studydata[:study_title]
          xml.STUDY_DESCRIPTION   studydata[:description]
          xml.CENTER_PROJECT_NAME studydata[:center_study_name]
          xml.CENTER_NAME         studydata[:center_name]
          xml.STUDY_ABSTRACT      studydata[:study_abstract]

          xml.PROJECT_ID(studydata[:study_id] || "0")
          study_type = studydata[:existing_study_type]
          if StudyType.include?(study_type)
            xml.STUDY_TYPE(:existing_study_type => study_type)
          else
            xml.STUDY_TYPE(:existing_study_type => Study::Other_type , :new_study_type => study_type)
          end
        }
            }
      }
    return xml.target!
  end

  def accession_sample_set_xml_quarantine(sample, sampledata)
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.SAMPLE_SET('xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance') {
      xml.SAMPLE(:alias => sampledata[:alias], :accession => sample.sample_metadata.sample_ebi_accession_number) {
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

        xml.SAMPLE_LINKS {

        } unless sampledata[:links].blank?
      }
    }
    return xml.target!
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
          :inform_on_error  => submission[:contact_inform_on_error],
          :inform_on_status => submission[:contact_inform_on_status],
          :name             => submission[:name]
        )
      }
      xml.ACTIONS {
        xml.ACTION {
          if accession_number.blank?
            xml.ADD(:source => submission[:source], :schema => submission[:schema])
          else
            xml.MODIFY(:source => submission[:source], :target=>"")
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
    return xml.target!
  end

  require 'rexml/document'
  require 'curb'
  include REXML

  def accession_login
    raise NotImplemented, "abstract method"
  end

  def post_files(file_params)
    raise StandardError, "Cannot connect to EBI to get accession number. Please configure accession_url in config.yml" if configatron.accession_url.blank?

    begin
      curl = Curl::Easy.new(URI.parse(configatron.accession_url+accession_login).to_s)
      if configatron.disable_web_proxy == true
        curl.proxy_url = ''
      elsif not configatron.proxy.blank?

        curl.proxy_url= configatron.proxy
        # UA required to get through Sanger proxy
        curl.headers["User-Agent"] = "Sequencescape Accession Client (#{RAILS_ENV})"
        curl.proxy_tunnel = true
        curl.verbose = true
      end

      curl.multipart_form_post = true
      curl.http_post(
        *file_params.map { |p| Curl::PostField.file(p[:name], p[:local_name], p[:remote_name]) }
      )
      case curl.response_code
      when (200...300) #success
        return curl.body_str
      when (400...600)
        Rails.logger.warn($!)
        $! = nil
        raise AccessionServiceError
      else
      return ""
      end
    rescue StandardError => exception
      raise AccessionServiceError, "Could not get accession number. EBI may be down or invalid data submitted: #{$!}"
    end
  end

end
