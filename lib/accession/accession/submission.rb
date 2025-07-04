# frozen_string_literal: true
module Accession
  # Made up of a sample, user and service
  # Used by Request to extract relevant information to send to appropriate accessioning service
  class Submission
    include ActiveModel::Model
    include Accession::Accessionable

    attr_reader :user, :sample, :service, :contact, :response

    delegate :accessioned?, to: :response

    delegate :ebi_alias, :ebi_alias_datestamped, to: :sample

    validates_presence_of :user, :sample
    validate :check_sample, if: proc { |s| s.sample.present? }

    def initialize(user, sample)
      @user = user
      @sample = sample
      @response = Accession::NullResponse.new

      if valid?
        @service = sample.service
        @contact = Contact.new(user)
      end
    end

    def to_xml # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
      xml = Builder::XmlMarkup.new
      xml.instruct!
      xml.SUBMISSION(
        XML_NAMESPACE,
        center_name: CENTER_NAME,
        broker_name: service.broker,
        alias: sample.ebi_alias_datestamped,
        submission_date: date
      ) do
        xml.CONTACTS { xml.CONTACT(contact.to_h) }

        xml.ACTIONS do
          xml.ACTION { xml.ADD(source: sample.filename, schema: sample.schema_type) }
          xml.ACTION { xml.tag!(service.visibility) }
        end
      end
      xml.target!
    end

    def post
      unless valid?
        error_message = "Accessionable submission is invalid: #{errors.full_messages.join(', ')}"
        Rails.logger.error(error_message)
        raise StandardError, error_message
      end

      @response = Accession::Request.post(self)
    end

    def update_accession_number
      sample.update_accession_number(response.accession_number) if accessioned?
    end

    def payload
      @payload ||= Payload.new([self, sample])
    end

    # Accessioning requires a submission and sample file
    # Payload consists of a hash of relevant files
    # These files can be opened when the request is sent
    class Payload
      include Enumerable

      attr_reader :files

      def initialize(accessionables)
        @files =
          {}.tap do |f|
            accessionables.each { |accessionable| f[accessionable.schema_type.upcase] = accessionable.to_file }
          end
      end

      def each(&)
        files.each(&)
      end

      def open
        files.transform_values(&:open)
      end

      def close!
        files.values.each(&:close!) # rubocop:todo Style/HashEachMethods
      end
    end

    private

    def check_sample
      sample.errors.each { |error| errors.add error.attribute, error.message } unless sample.valid?
    end
  end
end
