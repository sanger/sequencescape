# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2007-2011,2013,2014,2015,2016 Genome Research Ltd.

module Submission::AccessionBehaviour
  def self.included(base)
    base.class_eval do
      validate :check_data_release_and_accession_for_submission, if: :can_check_data_release_and_accession?
    end
  end

  def can_check_data_release_and_accession?
    study.present? && request_types_require_accessioning?
  end

  def request_types_require_accessioning?
    RequestType.find(request_types).detect(&:accessioning_required?)
  end

  def check_data_release_and_accession_for_submission
    return if configatron.disable_accession_check == true

    if not study.valid_data_release_properties?
      errors.add(:study, "#{study.name}: Please fill in the study data release information")
    elsif not study.ena_accession_required?
      # Nothing to do here because the study does not require ENA accessioning
    elsif not study.accession_number?
      errors.add(:study, "#{study.name} and all samples must have accession numbers")
    elsif not all_samples_have_accession_numbers?
      errors.add(:base, "The following samples are missing accession numbers: #{unaccessioned_samples}")
    end
  end

  private

  def test_asset_group
    AssetGroup.new(assets: assets)
  end

  def unaccessioned_samples
    test_asset_group.unaccessioned_samples.map(&:name).to_sentence
  end

  def all_samples_have_accession_numbers?
    test_asset_group.all_samples_have_accession_numbers?
  end
end
