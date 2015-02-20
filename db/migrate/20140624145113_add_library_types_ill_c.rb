#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
class AddLibraryTypesIllC < ActiveRecord::Migration

  def self.libraries_config
    { :illumina_c_multiplexed_library_creation =>    
          ["TraDIS qPCR only", "Transcriptome counting qPCR only",
          "Nextera single index qPCR only", "Nextera dual index qPCR only",
          "Bisulphate qPCR only",
          "TraDIS pre quality controlled",
          "Transcriptome counting pre quality controlled",
          "Nextera single index pre quality controlled",
          "Nextera dual index pre quality controlled",
          "Bisulphate pre quality controlled"],
      :illumina_c_library_creation => ["TraDIS qPCR only", 
          "Transcriptome counting qPCR only",
          "Nextera single index qPCR only", "Nextera dual index qPCR only",
          "Bisulphate qPCR only",
          "TraDIS pre quality controlled",
          "Transcriptome counting pre quality controlled",
          "Nextera single index pre quality controlled",
          "Nextera dual index pre quality controlled",
          "Bisulphate pre quality controlled"        
        ]
    }
  end
  
  def self.library_type_names(request_class_symbol)
    libraries_config[request_class_symbol]
  end
  
  def self.request_types_to_change
    libraries_config.keys
  end
  
  def self.up
    ActiveRecord::Base.transaction do
      request_types_to_change.each do |request_type| 
        self.create_library_types(request_type)
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      request_types_to_change.each do |request_type|
        self.clear_library_types(request_type)
      end
    end
  end

  def self.create_library_types(request_class_symbol)
    request_type = RequestType.find_by_key(request_class_symbol.to_s)
    library_type_names(request_class_symbol).each do |library_type_name|
      library_type = LibraryType.find_or_create_by_name(library_type_name)
      LibraryTypesRequestType.create!(:request_type=>request_type,:library_type=>library_type,:is_default=>false)
    end
  end
  
  def self.clear_library_types(request_class_symbol)
    library_types = LibraryType.find_all_by_name(library_type_names(request_class_symbol))
    unless library_types.empty?
      request_type = RequestType.find_by_key(request_class_symbol.to_s)
      unless request_type.nil?
        request_type.library_types.delete(library_types)
      end
      library_types.each(&:destroy)
    end
  end
end
