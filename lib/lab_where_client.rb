#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'rest-client'

module LabWhereClient

  LabwhereException = Class.new(StandardError)

  class LabWhere
    include Singleton

    def base_url
      configatron.labwhere_api
    end

    def path_to(instance, target)
      raise LabwhereException.new, "LabWhere service URL not set" if base_url.nil?
      [base_url, instance.endpoint, target].compact.join('/')
    end

    def get(instance, target)
      JSON.parse(RestClient.get(path_to(instance,target)))
    rescue Errno::ECONNREFUSED => e
      raise LabwhereException.new(e), "LabWhere service is down", e.backtrace
    end

    def post(instance, target, payload)
      parseJSON(RestClient.post(path_to(instance,target), payload))
    rescue Errno::ECONNREFUSED => e
      raise LabwhereException.new(e), "LabWhere service is down", e.backtrace
    rescue RestClient::UnprocessableEntity => e
      return parseJSON(e.response)
    end

    def put(instance, target, payload)
      parseJSON(RestClient.put(path_to(instance,target), payload))
    rescue Errno::ECONNREFUSED => e
      raise LabwhereException.new(e), "LabWhere service is down", e.backtrace
    end

  end

  class Endpoint

    def self.endpoint_name(name)
      @endpoint = name
    end

    class << self
      attr_reader :endpoint
    end

    def initialize(params)
    end

  end

  module EndpointCreateActions
    module ClassMethods
      def creation_params(params)
        params
      end

      def create(params)
        attrs = LabWhere.instance.post(self, nil, creation_params(params))
        new(attrs) unless attrs.nil?
      end
    end
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
  end

  module EndpointUpdateActions
    module ClassMethods
      def update(target, params)
        attrs = LabWhere.instance.put(self, target, params)
        new(attrs) unless attrs.nil?
      end
    end
    def self.included(base)
      base.send(:extend, ClassMethods)
    end
  end

  LabwhereException = Class.new(StandardError)

  class Labware < Endpoint
    endpoint_name 'labwares'

    attr_reader :barcode
    attr_reader :location

    def self.find_by_barcode(barcode)
      new(LabWhere.instance.get(self, barcode))
    end

    def initialize(params)
      @barcode = params['barcode']
      @location = Location.new(params['location'])
    end
  end

  class Scan < Endpoint
    include EndpointCreateActions

    attr_reader :message, :errors

    endpoint_name 'scans'

    def initialize(params)
      @message = params['message']
      @errors = params['errors']
    end

    def response_message
      @message
    end

    def self.creation_params(params)
      obj = params.dup
      obj[:labware_barcodes] = obj[:labware_barcodes].join("\n")
      { :scan => obj }
    end

    def valid?
      @errors.nil?
    end

    def error
      @errors.join(";")
    end

  end

  class Location < Endpoint
    endpoint_name 'locations'

    attr_reader :name
    attr_reader :parentage

    def initialize(params)
      @name = params['name']
      @parentage = params['parentage']
    end

    def location_info
      [parentage, name].join(' - ')
    end
  end

  class LocationType < Endpoint
    endpoint_name 'location_types'
  end
end
