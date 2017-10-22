require './lib/submission_serializer'

class AddHiseq4000SubmissionTemplates < ActiveRecord::Migration
  def up
    ActiveRecord::Base.transaction do
      each_template do |params|
        SubmissionSerializer.construct!(params)
      end
    end
  end

  def down
    ActiveRecord::Base.transaction do
      each_template do |params|
        SubmissionTemplate.find_by(name: params[:name]).destroy
      end
    end
  end

  def each_template
    # High Throughput

    ['illumina_htp_hiseq_4000_paired_end_sequencing', 'illumina_htp_hiseq_4000_single_end_sequencing'].each do |sequencing_key|
      [
        { request_types: ['illumina_a_shared', 'illumina_a_isc'], request_type_name: 'HTP ISC', product_catalogue: 'ISC', order_role: 'ISC' },
        { request_types: ['illumina_a_re_isc'], request_type_name: 'ISC Repool', product_catalogue: 'ReISC', order_role: 'ReISC' },
        { request_types: ['illumina_b_shared', 'illumina_b_pool'], request_type_name: 'Pooled MWGS', product_catalogue: 'MWGS', order_role: 'MWGS' },
        { request_types: ['illumina_b_shared', 'illumina_b_pool'], request_type_name: 'Pooled PWGS', product_catalogue: 'PWGS', order_role: 'PWGS' }

      ].each do |request_options|
        yield parameters('IHTP', 'Illumina-HTP', sequencing_key, request_options)
      end
    end
    # Bespoke
    ['illumina_c_hiseq_4000_paired_end_sequencing', 'illumina_c_hiseq_4000_single_end_sequencing'].each do |sequencing_key|
      [
        { request_types: ['illumina_c_nopcr'], request_type_name: 'General no PCR', product_catalogue: 'GenericNoPCR', order_role: 'NoPCR' },
        { request_types: ['illumina_c_pcr'], request_type_name: 'General PCR', product_catalogue: 'GenericPCR', order_role: 'PCR' },
        { request_types: ['illumina_c_library_creation'], request_type_name: 'Library Creation', product_catalogue: 'Generic', order_role: 'ILC' },
        { request_types: ['illumina_c_multiplexed_library_creation'], request_type_name: 'Multiplexed Library Creation', product_catalogue: 'ClassicMultiplexed', order_role: 'ILC' },
        { request_types: ['illumina_c_multiplexing'], request_type_name: 'Multiplex', product_catalogue: 'Generic', order_role: 'PCR' },
      ].each do |request_options|
        yield parameters('Illumina-C', 'Illumina-C', sequencing_key, request_options)
      end
    end
  end

  def parameters(prefix, product_line, sequencing_key, request_options)
    name = "#{prefix} - #{request_options[:request_type_name]} - #{sequencing_key}"
    {
      name: name,
      submission_class_name: 'LinearSubmission',
      product_line: product_line,
      product_catalogue: request_options[:product_catalogue],
      submission_parameters: {
        request_types: request_options[:request_types] + [sequencing_key],
        workflow: 'short_read_sequencing',
        order_role: request_options[:order_role]
      }
    }
  end
end
