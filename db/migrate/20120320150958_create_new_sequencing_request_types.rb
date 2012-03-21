class CreateNewSequencingRequestTypes < ActiveRecord::Migration
  def self.up
    Pipeline.find_all_by_sti_type('SequencingPipeline').each do |sequencing_pipeline|
      existing_request_type = sequencing_pipeline.request_types.last

      ProductLine.all.each do |product_line|
        sequencing_pipeline.request_types << RequestType.find_or_create_by_key(
          {
            'key'          => "#{product_line.name.underscore}_#{existing_request_type.key}",
            'name'         => "#{product_line.name} #{existing_request_type.name}",
            'product_line' => product_line
          }.reverse_merge(existing_request_type.attributes).except(*%w{id created_at updated_at})
        )
      end
    end
  end

  def self.down
  end
end
