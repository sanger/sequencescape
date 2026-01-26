# frozen_string_literal: true
class AccessionService::BaseService
  include REXML

  # We overide this in testing to do a bit of evesdropping
  class_attribute :rest_client_class
  self.rest_client_class = RestClient::Resource

  def provider
    'Base'
  end

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

      raise AccessionService::AccessionServiceError, errors.join("\n") unless errors.empty?

      files = [] # maybe not necessary, but just to be sure that the tempfile still exists when they are sent
      begin
        xml_result =
          post_files(
            submission.all_accessionables.map do |acc|
              file = Tempfile.open("#{acc.schema_type}_file")
              files << file
              file.puts(acc.xml)
              file.open # reopen for read

              Rails.logger.debug { file.each_line.to_a.join("\n") }

              { name: acc.schema_type.upcase, local_name: file.path, remote_name: acc.file_name }
            end
          )
        Rails.logger.debug { xml_result }
        if xml_result.match?(/(Server error|Auth required|Login failed)/)
          raise AccessionService::AccessionServiceError,
                "EBI Server Error. Could not get accession number: #{xml_result}"
        end

        xmldoc = Document.new(xml_result)
        success = xmldoc.root.attributes['success']
        accession_numbers = []

        # for some reasons, ebi doesn't give us back a accession number for the submission if it's a MODIFY action
        # therefore, we should be ready to get one or not
        number_generated = true
        case success
        when 'true'
          # extract and update accession numbers
          accession_number =
            submission.all_accessionables.each do |acc|
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

          raise AccessionService::NumberNotGenerated, 'Service gave no numbers back' unless number_generated
        when 'false'
          errors = xmldoc.root.elements.to_a('//ERROR').map(&:text)
          show_errors = 3

          current_errors = errors.first(show_errors)

          message = "#{provider} service returned #{errors.length} errors: #{current_errors.join('; ')}"

          errors_remaining = errors.length - show_errors
          more_messages = "- and #{errors_remaining} more errors" if errors_remaining.positive?

          raise AccessionService::AccessionServiceError,
                ['Could not get accession number.', $!.to_s, message, more_messages].compact.join(' ')
        else
          raise AccessionService::AccessionServiceError,
                "Could not get accession number. Error in submitted data: #{$!}"
        end
      ensure
        files.each(&:close) # not really necessary but recommended
      end
    end

    accessionables.map(&:accession_number)
  end

  def submit_sample_for_user(sample, user)
    submit(user, Accessionable::Sample.new(sample))
  end

  def submit_study_for_user(study, user)
    unless study.accession_required?
      raise AccessionService::NumberNotRequired,
            'An accession number is not required for this study'
    end

    # TODO: check error
    # raise AccessionServiceError, "Cannot generate accession number: #{ sampledata[:error] }" if sampledata[:error]

    # TODO: commented as not used without error handling
    # ebi_accession_number = study.study_metadata.study_ebi_accession_number

    # raise NumberNotGenerated, 'No need to' if not ebi_accession_number.blank? and not /ER/.match(ebi_accession_number)

    submit(user, Accessionable::Study.new(study))
  end

  def submit_dac_for_user(_study, _user)
    raise AccessionService::NumberNotRequired, 'No need to'
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
    AccessionService::PROTECT
  end

  def study_visibility(_study)
    AccessionService::PROTECT
  end

  def policy_visibility(_study)
    AccessionService::PROTECT
  end

  def dac_visibility(_study)
    AccessionService::PROTECT
  end

  def private?
    false
  end

  private

  def accession_submission_xml(submission, accession_number)
    xml = Builder::XmlMarkup.new
    xml.instruct!
    xml.SUBMISSION(
      'xmlns:xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
      :center_name => submission[:center_name],
      :broker_name => submission[:broker],
      :alias => submission[:submission_id],
      :submission_date => submission[:submission_date]
    ) do
      xml.CONTACTS do
        xml.CONTACT(
          inform_on_error: submission[:contact_inform_on_error],
          inform_on_status: submission[:contact_inform_on_status],
          name: submission[:name]
        )
      end
      xml.ACTIONS do
        xml.ACTION do
          if accession_number.blank?
            xml.ADD(source: submission[:source], schema: submission[:schema])
          else
            xml.MODIFY(source: submission[:source], target: '')
          end
        end
        xml.ACTION { submission[:hold] == AccessionService::PROTECT ? xml.PROTECT : xml.HOLD }
      end
    end
    xml.target!
  end

  def accession_options
    raise NotImplemented, 'abstract method'
  end

  def rest_client_resource
    rest_client_class.new(configatron.accession.url!, accession_options)
  end

  def post_files(file_params)
    rc = rest_client_resource

    if configatron.disable_web_proxy == true
      RestClient.proxy = nil
    elsif configatron.fetch(:proxy).present?
      RestClient.proxy = configatron.proxy

      # UA required to get through Sanger proxy
      # Although currently this UA is actually being set elsewhere in the
      # code as RestClient doesn't pass this header to the proxy.
      rc.options[:headers] = { user_agent: "Sequencescape Accession Client (#{Rails.env})" }
    elsif ENV['http_proxy'].present?
      RestClient.proxy = ENV['http_proxy']
    end

    payload =
      file_params.each_with_object({}) do |param, hash|
        hash[param[:name]] = AccessionedFile
          .open(param[:local_name])
          .tap { |f| f.original_filename = param[:remote_name] }
      end

    response = rc.post(payload)
    case response.code
    when (200...300)
      # success
      response.body.to_s
    when (400...600)
      # the $! notation is used to fetch the last exception in scope
      Rails.logger.warn($!)
      $! = nil
      raise AccessionService::AccessionServiceError
    else
      ''
    end
  rescue StandardError => e
    raise AccessionService::AccessionServiceError,
          "Could not get accession number. EBI may be down or invalid data submitted: #{$!}"
  end
end
