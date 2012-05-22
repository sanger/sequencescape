class PipelinesRequestType < ActiveRecord::Base; end

class CreateNewLibraryPrepRequestTypes < ActiveRecord::Migration
  LIB_PREP_REQUEST_TYPES = {
    'Illumina-A' => [ 
      'Cherrypicking for Pulldown',
      'Pulldown WGS',
      'Pulldown SC',
      'Pulldown ISC'
  ],
    'Illumina-C' => [ 'Library creation' ]
  }

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

      # Find the ProductLines and matching RequestTypes
      prd_and_rtypes = LIB_PREP_REQUEST_TYPES.inject({}) do |h, (prd_name, names)|
        h[ProductLine.find_by_name(prd_name)] = names.map {|name| RequestType.find_by_name(name)}; h
      end

      # Create new RequestTypes for the ProductLine
      prd_and_rtypes.each do |product_line, rtypes|
        rtypes.each do |rt| 
          new_rtype = product_lined_request_type(product_line, rt)

          # Add new RequestTypes to matching pipelines
          Pipeline.for_request_type(rt).each do |p| 
            p.request_types << new_rtype
            say "Adding RequestType: #{new_rtype.name} to Pipeline: #{p.name}"
          end

          say "Deprecating old RequestType: #{rt.name}"
          rt.update_attributes(:deprecated => true)
        end
      end

    end
    # Deprecate old RequestTypes...

    [
      'Pulldown library creation',
      'Pulldown Multiplex Library Preparation',
    ].each do |old_request_type|
      RequestType.find_by_name(old_request_type).update_attributes(:deprecated => true)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do

      keys = LIB_PREP_REQUEST_TYPES.map do |prd_name, rtypes|
        rtypes.map { |rtype_name| "#{prd_name}_#{rtype_name}".underscore.gsub(/\s/,'_') }
      end.flatten

      rtypes = RequestType.all(:conditions => ['`key` IN (?)', keys])

      PipelinesRequestType.all(
        :conditions => ['request_type_id IN(?)', rtypes.map(&:id)]
      ).each(&:destroy)

      rtypes.each(&:destroy)

      LIB_PREP_REQUEST_TYPES.values.flatten.each do |rt_name|
        RequestType.find_by_name(rt_name).tap do |rt|
          say "Undeprecating old RequestType: #{rt.name}"
          rt.update_attributes(:deprecated => false)
        end
      end
    end
  end
end
