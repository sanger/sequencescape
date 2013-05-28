module IlluminaC::Requests

  class LibraryRequest < Request::LibraryCreation

  end

  class PcrLibraryRequest < LibraryRequest
    LIBRARY_TYPES = [
      'Standard'
    ]

    DEFAULT_LIBRARY_TYPE = 'Standard'

    fragment_size_details(:no_default, :no_default)
  end

  class NoPcrLibraryRequest < LibraryRequest
    LIBRARY_TYPES = [
      'Standard'
    ]

    DEFAULT_LIBRARY_TYPE = 'Standard'

    fragment_size_details(:no_default, :no_default)
  end

  class InitialTransfer < TransferRequest
    include TransferRequest::InitialTransfer
  end

  module Helpers

    def create_request_types
      each_request_type do |params|
        RequestType.create!(params)
      end
      IlluminaC::PlatePurposes::STOCK_PLATE_PURPOSE_TO_OUTER_REQUEST.each do |purpose,request|
        RequestType.find_by_key(request).acceptable_plate_purposes << Purpose.find_by_name(purpose)
      end
    end

    def destroy_request_types
      each_request_type do |params|
        RequestType.find_by_name(params[:name]).destroy
      end
    end

    def each_request_type
      [
        {
          :name => 'Illumina-C Library Creation PCR',
          :key => 'illumina_c_pcr',
          :request_class_name =>'IlluminaC::Requests::PcrLibraryRequest'
        },
        {
          :name => 'Illumina-C Library Creation No PCR',
          :key => 'illumina_c_nopcr',
          :request_class_name =>'IlluminaC::Requests::NoPcrLibraryRequest'
        }
      ].each do |params|
         params.merge!({
          :workflow => Submission::Workflow.find_by_name("Next-gen sequencing"),
          :asset_type => 'Well',
          :order =>1,
          :initial_state =>'pending',
          :for_multiplexing =>true,
          :billable =>true,
          :target_purpose =>Purpose.find_by_name('ILC Lib Pool Norm'),
          :product_line => ProductLine.find_by_name('Illumina-C')
        })
        yield(params)
      end
    end

  end
  extend Helpers

end
