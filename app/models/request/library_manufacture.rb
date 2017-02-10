# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

# Any request involved in building a library should include this module that defines some of the
# most common behaviour, namely the library type and insert size information.
module Request::LibraryManufacture
  def self.included(base)
    base::Metadata.class_eval do
      attribute(:fragment_size_required_from, required: true, integer: true)
      attribute(:fragment_size_required_to,   required: true, integer: true)
      attribute(:library_type,                required: true, validator: true, selection: true)
    end

    base.class_eval do
      extend ClassMethods
    end

    base.const_set(:RequestOptionsValidator, Class.new(DelegateValidation::Validator) do
      delegate_attribute :fragment_size_required_from, :fragment_size_required_to, to: :target, type_cast: :to_i
      validates_numericality_of :fragment_size_required_from, integer_only: true, greater_than: 0
      validates_numericality_of :fragment_size_required_to,   integer_only: true, greater_than: 0
    end)
  end

  module ClassMethods
    def delegate_validator
      self::RequestOptionsValidator
    end
  end

  def insert_size
    Aliquot::InsertSize.new(
      request_metadata.fragment_size_required_from,
      request_metadata.fragment_size_required_to
    )
  end

  delegate :library_type, to: :request_metadata
end
