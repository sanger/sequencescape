# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

Given /^a "([^"]*)" tube called "([^"]*)" exists$/ do |tube_purpose, tube_name|
  purpose = Tube::Purpose.find_by!(name: tube_purpose)
  test = purpose.target_type.constantize.create!(
    name: tube_name,
    purpose: purpose
  )
end

Given /^the tube "([^"]*)" is the target of a (started|passed|pending) "([^"]*)" from "([^"]*)"$/ do |tube_name, state, request_type, source_name|
  submission = Submission.last || FactoryGirl.create(:submission)
  tube = Tube.find_by(name: tube_name)
  source = Asset.find_by(name: source_name)
  source = source.wells.first if source.is_a?(Plate)
  RequestType.find_by(name: request_type).create!(
    { state: state,
      asset: source,
      target_asset: tube,
      submission: submission
    }.merge(request_defaults(request_type))
  )
end

Given /^a (started|passed|pending) transfer from the stock tube "([^"]*)" to the MX tube$/ do |state, source_name|
  source = Tube.find_by(name: source_name) or raise "Cannot find source tube #{source_name.inspect}"
  Transfer::BetweenTubesBySubmission.create!(
    source: source,
    user: User.last || User.create(login: 'no_one')
  )
  step %Q{the transfer requests on "#{source.id}" are #{state}}
end

Given /^I am setup to test tubes with plate set (\d+)$/ do |num|
  step %Q{the plate barcode webservice returns "#{num}000001"}
  step %Q{a "ILB_STD_INPUT" plate called "source plate #{num}" exists}
  step %Q{plate "source plate #{num}" has "1" wells with aliquots}
  step %Q{the plate barcode webservice returns "#{num}000002"}
  step %Q{a "ILB_STD_PCRXP" plate called "middle plate #{num}" exists}
  step %Q{plate "middle plate #{num}" has "1" wells with aliquots}
  step %Q{passed transfer requests exist between 1 wells on "source plate #{num}" and "middle plate #{num}"}
end

Given(/^the tube with ID (\d+) has a custom metadatum collection with UUID "(.*?)"$/) do |id, uuid|
    metadata = [FactoryGirl.build(:custom_metadatum, key: 'Key1', value: 'Value1'),
                FactoryGirl.build(:custom_metadatum, key: 'Key2', value: 'Value2')]
    collection = FactoryGirl.create(:custom_metadatum_collection, custom_metadata: metadata, asset_id: id)
    set_uuid_for(collection, uuid)
end

def request_defaults(type)
  {
    'Illumina-B STD' => {
      request_metadata_attributes: {
        fragment_size_required_from: 300,
        fragment_size_required_to: 300
      }
    }
  }[type] || {}
end

Given /^the transfer requests on "([^"]*)" are (pending|passed|started)$/ do |source_id, state|
  unless state == 'pending'
    Asset.find(source_id).requests.each do |request|
      if request.is_a?(TransferRequest)
        request.start!
        request.pass! unless state == 'started'
      end
    end
  end
end
