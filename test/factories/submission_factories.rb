# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012 Genome Research Ltd.
FactoryGirl.define do
  factory :submission__ do |submission|
    # raise "call FactoryHelp::submission instead "
    factory :submission_without_order do
      user
    end
  end

  # TODO move in a separate file
  # easier to keep it here at the moment because we are moving stuff between both
  factory :order do |order|
    study
    workflow              { |workflow| workflow.association(:submission_workflow) }
    project
    user
    item_options          {}
    request_options       {}
    assets                []
    request_types         { [create(:request_type).id] }

    factory :order_with_submission do
      after(:build) { |o| o.create_submission(user_id: o.user_id) }
    end
  end
end

class FactoryHelp
  def self.submission(options)
    submission_options = {}
    [:message, :state].each do |option|
      value = options.delete(option)
      submission_options[option] = value if value
    end
    state = options.delete(:state)
    message = options.delete(:message)
    submission = FactoryGirl.create(:order_with_submission, options).submission
    # trying to skip StateMachine
    if submission_options.present?
      submission.update_attributes!(submission_options)
    end
    submission.reload
  end
end
