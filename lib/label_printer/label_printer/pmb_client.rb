#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'rest-client'

module LabelPrinter

	class PmbClient

		def self.base_url
      configatron.pmb_api
    end

    def self.print_job_url
    	"#{base_url}/print_jobs"
    end

    def self.label_templates_url
      "#{base_url}/label_templates"
    end

    def self.headers
    	{content_type: "application/vnd.api+json", accept: "application/vnd.api+json"}
    end

    def self.print(attributes)
      RestClient.post print_job_url, {"data"=>{"attributes"=>attributes}}.to_json, headers
    rescue RestClient::UnprocessableEntity => e
      return e.response
    rescue Errno::ECONNREFUSED => e
      return e
    end

    def self.get_label_template_by_name(name)
      JSON.parse(RestClient.get "#{label_templates_url}?filter[name]=#{name}", headers)
    end
	end

end