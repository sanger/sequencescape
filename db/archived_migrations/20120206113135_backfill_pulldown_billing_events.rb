#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
class BackfillPulldownBillingEvents < ActiveRecord::Migration
  BACKFILL_ENTRY_DATE = Time.parse('31-Jan-2012 12:00')

  def self.bill_for(target, request)
    BillingEvent.send(:"bill_#{target}_for", request).map do |billing_event|
      billing_event.entry_date = BACKFILL_ENTRY_DATE
      billing_event.save(:validate => false)
    end
  rescue BillingException::DuplicateCharge => exception
    say "Appears that #{request.id} has already been billed"
  rescue BillingException::DuplicateChargeInternally => exception
    say "Appears that #{request.id} has already been internally billed"
  end

  def self.up
    ActiveRecord::Base.transaction do
      Pulldown::Requests::LibraryCreation.passed.find_each { |r| bill_for(:projects, r) }
      Pulldown::Requests::LibraryCreation.failed.find_each { |r| bill_for(:internally, r) }
    end
  end

  def self.down
    # Nothing to do here.
  end
end
