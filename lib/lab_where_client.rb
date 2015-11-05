#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require 'rest-client'

module LabWhereClient
  @@CACHED_INSTANCES= {}

  def self.load_params(obj, params)
    params.each do |k,v|
      obj.instance_variable_set("@#{k.to_s}", v)
      unless obj.methods.include?(k.to_s)
        obj.class.instance_eval do
          attr_reader "#{k}"
        end
      end
    end
    obj
  end

  def self.build_from_object(klass, params)
    return params if params.nil?
    if params.kind_of? Array
      params.map do |obj|
        LabWhereClient::load_params(klass.new, obj)
      end
    else
      LabWhereClient::load_params(klass.new, params)
    end
  end

  def self.json_retriever(url)
    json = RestClient.get(url)
    return nil if json == 'null'
    JSON.parse(json)
  end

  def self.build_from_url(klass, url)
    @@CACHED_INSTANCES[url] ||= LabWhereClient.build_from_object(klass, LabWhereClient.json_retriever(url))
  end

  def self.included(base)
    base.instance_eval do
      def define_rest_accessor(name, params={})
        klass_name = params[:as] || name.to_s.classify
        class_eval %Q{
          def #{name.to_s}
            if instance_variable_get("@#{name.to_s}")=="Empty"
              return nil
            end
            LabWhereClient::build_from_url(#{klass_name}, configatron.labwhere_api+instance_variable_get("@#{name.to_s}"))
          end
        }
      end
      def define_json_accessor(name, params={})
        klass_name = params[:as] || name.to_s.classify
        class_eval %Q{
          def #{name.to_s}
            LabWhereClient::build_from_object(#{klass_name}, instance_variable_get("@#{name.to_s}"))
          end
        }
      end

    end
  end


  class Location
    @@MAX_DEPTH_ANCESTORS_LOCATIONS = 10

    include LabWhereClient

    define_rest_accessor :labwares
    define_rest_accessor :audits
    define_rest_accessor :parent, :as => Location
    define_rest_accessor :children, :as => Location

    def location_type
      LabWhereClient::build_from_url(LabWhereClient::LocationType, "#{configatron.labwhere_api}/api/location_types/#{location_type_id}")
    end

    def self.find_by_barcode(barcode)
      LabWhereClient::build_from_url(LabWhereClient::Location, "#{configatron.labwhere_api}/api/locations/#{barcode}")
    end

    def ancestors(depth=0)
      return [self, parent.ancestors(depth+1)].flatten.compact unless (parent.nil? || (depth > @@MAX_DEPTH_ANCESTORS_LOCATIONS))
      [self]
    end

    def ancestors_classified_by_location_type(location_type_list)
      location_type_list.map do |location_type|
        ancestors.select{|l| l.location_type.name == location_type}
      end
    end

    def location_info
      info = HashWithIndifferentAccess.new
      { 'storage_device' => [ "Box",  "Shelf", "Freezer -80C", "Incubator 37C"],
        'storage_area' => ["Room"],
        'building' => ["Building"],
        'building_area' => ["Site"]
      }.each do |location_tag,location_type_list|
        info[location_tag] = ancestors_classified_by_location_type(location_type_list).flatten.compact.map(&:name).join('|')
      end
      return info
    end
  end

  class Labware

    include LabWhereClient
    define_json_accessor :location
    define_rest_accessor :audits
    define_rest_accessor :parent, :as => Location
    define_rest_accessor :children, :as => Location

    def self.find_by_barcode(barcode)
      LabWhereClient::build_from_url(LabWhereClient::Labware, "#{configatron.labwhere_api}/api/labwares/#{barcode}")
    end

  end

  class Parent
    include LabWhereClient
  end

  class RecordData
    include LabWhereClient
  end

  class LocationType
    include LabWhereClient
  end

  class Audit
    include LabWhereClient
    define_json_accessor :record_data, :as => RecordData
  end

end
