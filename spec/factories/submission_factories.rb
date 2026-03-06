# frozen_string_literal: true

FactoryBot.define do
  factory :submission__ do
    user
    factory :submission_without_order
  end

  factory :submission do
    user
  end

  factory :submission_template do
    transient do
      project { nil }
      study { nil }
      request_types { [] }
    end

    submission_class_name { LinearSubmission.name }
    sequence(:name) { |i| "Template #{i}" }
    submission_parameters do
      {
        request_type_ids_list: request_types.map { |rt| [rt.id] },
        project_id: project&.id,
        study_id: study&.id
      }.compact
    end
    product_catalogue { |pc| pc.association(:single_product_catalogue) }

    factory :cherrypick_submission_template do
      name { 'Cherrypick' }
      request_types { create_list(:cherrypick_request_type, 1) }
    end

    factory :limber_wgs_submission_template do
      transient { request_types { [create(:library_request_type)] } }
    end

    factory :library_and_sequencing_template do
      transient { request_types { [create(:library_request_type), create(:sequencing_request_type)] } }
    end

    factory :heron_library_and_sequencing_template do
      transient { request_types { [create(:heron_request_type), create(:sequencing_request_type)] } }
    end

    factory :isc_library_and_sequencing_template do
      transient { request_types { [create(:isc_library_request_type), create(:sequencing_request_type)] } }
    end

    factory :pbmc_pooling_submission_template do
      transient { request_types { [create(:pbmc_pooling_customer_request_type)] } }
    end
  end

  factory :order do
    study
    project
    user
    request_options {}
    assets { create_list(:sample_tube, 1).map(&:receptacle) }
    request_types { [create(:request_type).id] }

    factory :order_with_submission do
      after(:build) { |order| order.create_submission(user_id: order.user_id) }
    end
  end

  factory :order_role do
    role { 'test_role' }
  end

  factory :linear_submission do
    study
    project
    user
    submission
    assets { create_list(:sample_tube, 1).map(&:receptacle) }
    request_types { [create(:request_type).id] }

    factory :library_order do
      assets { create_list(:untagged_well, 1) }
      request_types { [create(:library_request_type).id] }
      request_options do
        {
          fragment_size_required_from: 100,
          fragment_size_required_to: 200,
          library_type: 'Standard',
          bait_library_name: 'Bait'
        }
      end
      template_name { 'test_template_name' }
      order_role { create(:order_role) }
    end
  end

  factory :flexible_submission do
    study
    project
    user
    submission
    assets { create_list(:sample_tube, 1).map(&:receptacle) }
    request_types { [create(:request_type).id] }
  end

  factory :automated_order do
    user
    request_types { create_list(:sequencing_request_type, 1).map(&:id) }
    assets { create_list(:library_tube, 1).map(&:receptacle) }
  end

  # Builds a submission on the provided assets suitable for processing through
  # an external library pipeline such as Limber
  # Note: Not yet complete. (Just in case something crops up before I finish this!)
  factory :library_submission, class: 'Submission' do
    transient do
      assets { [create(:well)] }
      request_types { [create(:library_request_type), create(:multiplex_request_type)] }
    end

    user
    after(:build) do |submission, evaluator|
      submission.orders << build(
        :library_order,
        assets: evaluator.assets,
        request_types: evaluator.request_types.map(&:id)
      )
    end
  end
end

class FactoryHelp
  def self.submission(options)
    submission_options = {}
    %i[message state].each do |option|
      value = options.delete(option)
      submission_options[option] = value if value
    end
    submission = FactoryBot.create(:order_with_submission, options).submission

    # trying to skip StateMachine
    submission.update!(submission_options) if submission_options.present?
    submission.reload
  end
end
