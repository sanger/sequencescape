#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2015 Genome Research Ltd.
module PlatePurpose::Library
  def self.included(base)
    base.class_eval do
      include PlatePurpose::WorksOnLibraryRequests
    end
  end

  STATES_TO_ASSIGN_LIBRARY_INFORMATION = [ 'started', 'passed' ]

  def transition_to(plate, state, user, contents = nil, customer_accepts_responsibility = false)
    super
    assign_library_information_to_wells(plate) if STATES_TO_ASSIGN_LIBRARY_INFORMATION.include?(state)
  end

  # Ensure that the library information within the aliquots of the well is correct.
  def assign_library_information_to_wells(plate)
    each_well_and_its_library_request(plate) do |well, library_request|
      library_type, insert_size = library_request.library_type, library_request.insert_size

      well.aliquots.each do |aliquot|
        aliquot.library      ||= well
        aliquot.library_type ||= library_type
        aliquot.insert_size  ||= insert_size
        aliquot.save!
      end
    end
  end
  private :assign_library_information_to_wells
end
