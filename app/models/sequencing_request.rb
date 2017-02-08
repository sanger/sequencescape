# encoding: utf-8
# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015,2016 Genome Research Ltd.

class SequencingRequest < CustomerRequest
  extend Request::AccessioningRequired
  include Api::Messages::FlowcellIO::LaneExtensions

  has_metadata as: Request do
    # redundant with library creation , but THEY are using it .
    attribute(:fragment_size_required_from, required: true, integer: true)
    attribute(:fragment_size_required_to, required: true, integer: true)

    attribute(:read_length, integer: true, validator: true, required: true, selection: true)
  end

  include Request::CustomerResponsibility

  before_validation :clear_cross_projects
  def clear_cross_projects
    self.initial_project = nil if submission.try(:cross_project?)
    self.initial_study   = nil if submission.try(:cross_study?)
  end
  private :clear_cross_projects

  def create_assets_for_multiplexing
    barcode = AssetBarcode.new_barcode
    # Needs a sample?
    puldown_mx_library = PulldownMultiplexedLibraryTube.create!(name: barcode.to_s, barcode: barcode)
    lane = Lane.create!(name: puldown_mx_library.name)

    update_attributes!(asset: puldown_mx_library, target_asset: lane)
  end

  class RequestOptionsValidator < DelegateValidation::Validator
    delegate :fragment_size_required_from, :fragment_size_required_to, to: :target
    validates_numericality_of :fragment_size_required_from, integer_only: true, greater_than: 0
    validates_numericality_of :fragment_size_required_to, integer_only: true, greater_than: 0
  end

  def order=(_)
    # Do nothing
  end

  def ready?
    # It's ready if I don't have any lib creation requests or if all my lib creation requests are closed and
    # at least one of them is in 'passed' status
    asset = self.asset
    return true if asset.nil?
    requests_as_target = self.asset.requests_as_target
    return true if requests_as_target.nil?
    library_creation_requests = requests_as_target.where_is_a? Request::LibraryCreation
    (library_creation_requests.size == 0) || library_creation_requests.all?(&:closed?) && library_creation_requests.any?(&:passed?)
  end

  def self.delegate_validator
    SequencingRequest::RequestOptionsValidator
  end

  def concentration
    return ' ' if lab_events_for_batch(batch).empty?
    conc = lab_events_for_batch(batch).first.descriptor_value('Concentration')
    return "#{conc}μl" if conc.present?
    dna = lab_events_for_batch(batch).first.descriptor_value('DNA Volume')
    rsb = lab_events_for_batch(batch).first.descriptor_value('RSB Volume')
    "#{dna}μl DNA in #{rsb}μl RSB"
  end
end
