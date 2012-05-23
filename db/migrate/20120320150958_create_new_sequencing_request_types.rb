class PipelinesRequestType < ActiveRecord::Base; end

class CreateNewSequencingRequestTypes < ActiveRecord::Migration
  def self.product_lined_request_type(product_line, request_type)
    RequestType.find_or_create_by_key(
      {
        'key'          => product_lined_key(product_line, request_type),
        'name'         => "#{product_line.name} #{request_type.name}",
        'product_line' => product_line
      }.reverse_merge(request_type.attributes).except(*%w{id created_at updated_at})
    )
  end

  def self.product_lined_key(product_line, request_type)
    "#{product_line.name.underscore}_#{request_type.key}"
  end

  def self.up
    ActiveRecord::Base.transaction do
      Pipeline.find_all_by_sti_type('SequencingPipeline').each do |sequencing_pipeline|
        existing_request_type = sequencing_pipeline.request_types.last

        ProductLine.all.each do |product_line|
          next if product_line.name != 'Illumina-C' && existing_request_type.name =~ /MiSeq/
          request_type = product_lined_request_type(product_line, existing_request_type)

          next if sequencing_pipeline.request_types.include?(request_type)

          sequencing_pipeline.request_types << request_type
        end

        say "Deprecating old RequestType: #{existing_request_type.name}"
        existing_request_type.update_attributes(:deprecated => true)
      end

    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      pipelined_seq_request_types = RequestType.all(:conditions => ['`key` LIKE ?', 'illumina_%_sequencing'])

      PipelinesRequestType.all(
        :conditions => ['request_type_id IN(?)', pipelined_seq_request_types.map(&:id)]
      ).each(&:destroy)

      pipelined_seq_request_types.each(&:destroy)
    end
  end
end
