# frozen_string_literal: true

module AccessionV1ClientHelper
  # Stubs a method on an AccessioningV1Client instance double.
  #
  # @param fn_name [Symbol] The method name to stub (e.g., :submit_and_fetch_accession_number)
  # @param fn_args [Array] The arguments to expect when the method is called
  # @param return_value [Object, nil] The value to return from the stubbed method (default: nil)
  # @param raise_error [Exception, nil] The error to raise from the stubbed method (default: nil)
  # @return [RSpec::Mocks::InstanceVerifyingDouble] The mocked client
  def stub_accession_client(fn_name, *fn_args, return_value: nil, raise_error: nil)
    stimulus = stimulus(fn_name, *fn_args)

    if raise_error
      stimulus.and_raise(raise_error)
    else
      stimulus.and_return(return_value)
    end

    _mock_client
  end

  private

  def _mock_client
    @mock_client ||= instance_double(HTTPClients::AccessioningV1Client)
  end

  def stimulus(fn_name, *fn_args)
    if fn_args.empty?
      allow(_mock_client).to receive(fn_name)
    else
      allow(_mock_client).to receive(fn_name).with(*fn_args)
    end
  end

  module_function :stub_accession_client
end
