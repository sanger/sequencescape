#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'rest-client'

module LabelPrinter

  PmbException = Class.new(StandardError)

  class PmbClient

		def self.base_url
      configatron.pmb_api
    end

    def self.print_job_url
    	"#{base_url}/print_jobs"
    end

    def self.label_templates_filter_url
      "#{base_url}/label_templates?filter[name]="
    end

    def self.headers
    	{content_type: "application/vnd.api+json", accept: "application/vnd.api+json"}
    end

    def self.print(attributes)
      RestClient.post print_job_url, {"data"=>{"attributes"=>attributes}}.to_json, headers
    rescue RestClient::UnprocessableEntity => e
      raise PmbException.new(e), e.response
    rescue Errno::ECONNREFUSED => e
      raise PmbException.new(e), "PrintMyBarcode service is down"
    end

    def self.get_label_template_by_name(name)
      JSON.parse(RestClient.get "#{label_templates_filter_url}#{name}", headers)
    rescue RestClient::UnprocessableEntity => e
      raise PmbException.new(e), e.response
    rescue Errno::ECONNREFUSED => e
      raise PmbException.new(e), "PrintMyBarcode service is down"
    end
	end

end