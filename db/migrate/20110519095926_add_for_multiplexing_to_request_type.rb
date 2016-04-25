#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011 Genome Research Ltd.
class AddForMultiplexingToRequestType < ActiveRecord::Migration
  class RequestType < ActiveRecord::Base
    self.table_name =('request_types')

    def request_class
      @request_class ||= request_class_name.constantize
    end

    def for_multiplexing?
      request_class.ancestors.include?(MultiplexedLibraryCreationRequest) || request_class.ancestors.include?(PulldownMultiplexedLibraryCreationRequest) || request_class.ancestors.include?(CherrypickForPulldownRequest)
    end
  end

  def self.up
    add_column :request_types, :for_multiplexing, :boolean, :default => false

    RequestType.reset_column_information
    RequestType.transaction do
      RequestType.find_each do |request_type|
        request_type.update_attributes!(:for_multiplexing => request_type.for_multiplexing?)
      end
    end
  end

  def self.down
    remove_column :request_types, :for_multiplexing
  end
end
