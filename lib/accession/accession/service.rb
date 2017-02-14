module Accession
  # Provide all of the configuration relating to the type of accessioning.
  # Used by Accession::Request to send to the correct service.
  class Service
    include ActiveModel::Validations

    PROVIDERS = { 'managed' => :EGA, 'open' => :ENA }

    attr_reader :provider

    validates_presence_of :provider

    def initialize(study_type = nil)
      @provider = PROVIDERS[study_type]
    end

    def ena?
      provider == :ENA
    end

    def ega?
      provider == :EGA
    end

    def visibility
      ena? ? 'HOLD' : 'PROTECT'
    end

    def broker
      ega? ? provider.to_s : ''
    end

    def url
      configatron.accession.url! if valid?
    end

    def login
      return configatron.accession.ega!.to_hash if ega?
      return configatron.accession.ena!.to_hash if ena?
    end
  end
end
