#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2013,2014 Genome Research Ltd.
class PacBioSequencingRequest < Request

  SEQUENCING_TYPE = ["Standard","MagBead","Strobe","Circular"]
  has_metadata :as => Request  do
    attribute(:insert_size,      :validator => true, :required => true, :integer => true, :selection =>true  )
    attribute(:sequencing_type,  :validator => true, :required => true, :selection =>true                    )
  end

  include Request::CustomerResponsibility

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate_attribute :insert_size, :to => :target, :type_cast => :to_i
    validates_numericality_of :insert_size, :integer_only => true, :greater_than => 0

    # validates_inclusion_of :insert_size, :in => PacBioSequencingRequest::INSERT_SIZE

    delegate_attribute :sequencing_type, :to => :target
  end

  def self.delegate_validator
    PacBioSequencingRequest::RequestOptionsValidator
  end

end
