# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2014,2015 Genome Research Ltd.

module IlluminaC::Requests
  class LibraryRequest < Request::LibraryCreation
    def role; "#{request_metadata.library_type} #{order.role}"; end

    # Pop the request type in the pool information
    def update_pool_information(pool_information)
      super
      pool_information[:request_type] = request_type.name
    end

    fragment_size_details(:no_default, :no_default)
  end

  # The following two classes are redundant and are due for removal:
  # Stage 1:
  # Refactor to allow use of IlluminaC::Requests::LibraryRequest [Done: This commit]
  # Step 2:
  # Write migration to update existing request types / requests to use IlluminaC::Requests::LibraryRequest [Will be done soon]
  # Also update the configuration below to ensure the seeds behave correctly
  # Step 3:
  # Remove these classes
  # By splitting this process over three releases we avoid the need for downtime during migrations
  class PcrLibraryRequest < LibraryRequest
  end
  class NoPcrLibraryRequest < LibraryRequest
  end

  module Helpers
    def create_request_types
      each_request_type do |params|
        RequestType.create!(params)
      end
      IlluminaC::PlatePurposes::STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST.each do |purpose, request|
        RequestType.find_by(key: request).acceptable_plate_purposes << Purpose.find_by(name: purpose)
      end
    end

    def destroy_request_types
      each_request_type do |params|
        RequestType.find_by(name: params[:name]).destroy
      end
    end

    def each_request_type
      [
        {
          name: 'Illumina-C Library Creation PCR',
          key: 'illumina_c_pcr',
          for_multiplexing: true,
          request_class_name: 'IlluminaC::Requests::PcrLibraryRequest',
          target_purpose: Purpose.find_by(name: 'ILC Lib Pool Norm')
        },
        {
          name: 'Illumina-C Library Creation No PCR',
          key: 'illumina_c_nopcr',
          for_multiplexing: true,
          request_class_name: 'IlluminaC::Requests::NoPcrLibraryRequest',
          target_purpose: Purpose.find_by(name: 'ILC Lib Pool Norm')
        },
        {
          name: 'Illumina-C Library Creation PCR No Pooling',
          key: 'illumina_c_pcr_no_pool',
          request_class_name: 'IlluminaC::Requests::PcrLibraryRequest',
          for_multiplexing: false
        },
        {
          name:               'Illumina-C Library Creation No PCR No Pooling',
          key:                'illumina_c_no_pcr_no_pool',
          request_class_name: 'IlluminaC::Requests::NoPcrLibraryRequest',
          for_multiplexing:   false
        },
        {
          name:               'Illumina-C Chromium library creation',
          key:                'illumina_c_chromium_library',
          request_class_name: 'IlluminaC::Requests::LibraryRequest', # See class deprecation notice above
          for_multiplexing:   true,
          target_purpose:     Purpose.find_by(name: 'ILC Lib Pool Norm')
        },
        {
          name:               'Illumina-C Multiplexing',
          key:                'illumina_c_multiplexing',
          request_class_name: 'Request::Multiplexing',
          for_multiplexing:   true,
          target_purpose:     Purpose.find_by(name: 'ILC Lib Pool Norm')
        }
      ].each do |params|
         params.merge!(workflow: Submission::Workflow.find_by(name: 'Next-gen sequencing'),
                       asset_type: 'Well',
                       order: 1,
                       initial_state: 'pending',
                       billable: true,
                       product_line: ProductLine.find_by(name: 'Illumina-C'))
        yield(params)
      end
    end
  end
  extend Helpers
end
