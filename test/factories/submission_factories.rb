# This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012 Genome Research Ltd.
FactoryGirl.define do
  factory :submission__ do
    factory :submission_without_order do
      user
    end
  end

  factory :order do
    study
    workflow { |workflow| workflow.association(:submission_workflow) }
    project
    user
    item_options          {}
    request_options       {}
    assets                []
    request_types         { [create(:request_type).id] }

    factory :order_with_submission do
      after(:build) { |o| o.create_submission(user_id: o.user_id) }
    end

    factory :library_order do
      request_options { { fragment_size_required_from: 100, fragment_size_required_to: 200, library_type: 'Standard' } }
    end
  end

  # Builds a submission on the provided assets suitable for processing through
  # an external library pipeline such as Limber
  # Note: Not yet complete. (Just in case something crops up before I finish this!)
  factory :library_submission, class: Submission do
    transient do
      assets { [create(:well)] }
      request_types { [create(:library_request_type), create(:multiplex_request_type)] }
    end

    user
    after(:build) do |submission, evaluator|
      submission.orders << build(:library_order, assets: evaluator.assets, request_types: evaluator.request_types.map(&:id))
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
    submission = FactoryGirl.create(:order_with_submission, options).submission
    # trying to skip StateMachine
    if submission_options.present?
      submission.update_attributes!(submission_options)
    end
    submission.reload
  end
end
