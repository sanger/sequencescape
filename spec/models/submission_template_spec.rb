# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SubmissionTemplate do
  describe 'validations' do
    it 'is valid with valid attributes' do
      submission_template = build(:submission_template)
      expect(submission_template).to be_valid
    end

    context 'without a name' do
      let(:submission_template) { build(:submission_template, name: nil) }

      before { submission_template.validate }

      it 'is not valid' do
        expect(submission_template).not_to be_valid
      end

      it 'has an error on name' do
        expect(submission_template.errors[:name]).to include("can't be blank")
      end
    end

    context 'without a submission_class_name' do
      let(:submission_template) { build(:submission_template, submission_class_name: nil) }

      before { submission_template.validate }

      it 'is not valid' do
        expect(submission_template).not_to be_valid
      end

      it 'has an error on submission_class_name' do
        expect(submission_template.errors[:submission_class_name]).to include("can't be blank")
      end
    end

    context 'without a product_catalogue' do
      let(:submission_template) { build(:submission_template, product_catalogue: nil) }

      before { submission_template.validate }

      it 'is not valid' do
        expect(submission_template).not_to be_valid
      end

      it 'has an error on product_catalogue' do
        expect(submission_template.errors[:product_catalogue]).to include("can't be blank")
      end
    end
  end

  describe 'scopes' do
    describe '.visible' do
      it 'includes templates that are not superceded and not automated' do
        visible_template = create(:submission_template, superceded_by_id: SubmissionTemplate::LATEST_VERSION,
                                                        automated: false)
        # Automated template
        create(:submission_template, superceded_by_id: SubmissionTemplate::LATEST_VERSION, automated: true)
        # Superceded templates
        create(:submission_template, superceded_by_id: 1, automated: false)
        # Superceded and automated template
        create(:submission_template, superceded_by_id: 1, automated: true)

        expect(described_class.visible).to eq([visible_template])
      end
    end

    describe '.hidden' do
      it 'includes templates that are superceded' do
        # Superceded templates
        hidden_template1 = create(:submission_template, superceded_by_id: 1, automated: false)
        hidden_template2 = create(:submission_template, superceded_by_id: 1, automated: true)
        # Not superceded template
        create(:submission_template, superceded_by_id: SubmissionTemplate::LATEST_VERSION, automated: false)

        expect(described_class.hidden).to eq([hidden_template1, hidden_template2])
      end
    end

    describe '.include_product_line' do
      it 'includes associated product line' do
        product_line = create(:product_line)
        create(:submission_template, product_line:)

        expect(described_class.include_product_line.first.product_line).to eq(product_line)
      end
    end
  end

  describe '#grouped_by_product_lines' do
    it 'groups visible templates by product line name' do
      product_line = create(:product_line)
      submission_list = create_list(:submission_template, 5, product_line:)

      expect(described_class.grouped_by_product_lines).to eq({ product_line.name => submission_list })
    end

    it 'groups templates without a product line under "General"' do
      submission_list = create_list(:submission_template, 5, product_line: nil)

      expect(described_class.grouped_by_product_lines).to eq({ 'General' => submission_list })
    end
  end

  describe '#visible' do
    let(:submission_template) { described_class.new(name: 'test submission') }

    context 'when superceded_by_id is LATEST_VERSION and automated is false' do
      it 'returns true' do
        submission_template.superceded_by_id = SubmissionTemplate::LATEST_VERSION
        submission_template.automated = false
        expect(submission_template.visible).to be true
      end
    end

    context 'when superceded_by_id is LATEST_VERSION and automated is true' do
      it 'returns false' do
        submission_template.superceded_by_id = SubmissionTemplate::LATEST_VERSION
        submission_template.automated = true
        expect(submission_template.visible).to be false
      end
    end

    context 'when superceded_by_id is not LATEST_VERSION and automated is false' do
      it 'returns false' do
        submission_template.superceded_by_id = 1
        submission_template.automated = false
        expect(submission_template.visible).to be false
      end
    end

    context 'when superceded_by_id is not LATEST_VERSION and automated is true' do
      it 'returns false' do
        submission_template.superceded_by_id = 1
        submission_template.automated = true
        expect(submission_template.visible).to be false
      end
    end
  end

  describe '#superceded_by_unknown!' do
    it 'sets superceded_by_id to SUPERCEDED_BY_UNKNOWN_TEMPLATE' do
      submission_template = create(:submission_template)
      submission_template.superceded_by_unknown!
      expect(submission_template.superceded_by_id).to eq(SubmissionTemplate::SUPERCEDED_BY_UNKNOWN_TEMPLATE)
    end
  end

  describe '#supercede' do
    let(:original_template) { create(:submission_template, name: 'Original Template') }
    let(:cloned_template) { described_class.find_by(name: 'Cloned Template') }

    before do
      original_template.supercede do |cloned|
        cloned.name = 'Cloned Template'
      end
    end

    it 'creates a new submission template' do
      expect(described_class.count).to eq(2)
    end

    it 'sets cloned template superceded_by_id to LATEST_VERSION' do
      expect(cloned_template.superceded_by_id).to eq(SubmissionTemplate::LATEST_VERSION)
    end

    it 'updates original template attributes' do
      expect(original_template).to have_attributes(
        superceded_by_id: cloned_template.id,
        superceded_at: be_present
      )
    end
  end

  describe '#create_order!' do
    subject(:order) { submission_template.create_order!(order_attributes) }

    let!(:request_types) { create_list(:request_type, 2) }
    let!(:submission_template) do
      create(:submission_template, submission_parameters: {
               request_type_ids_list: request_types.map(&:id)
             })
    end
    let!(:user) { create(:user) }
    let!(:study) { create(:study) }
    let!(:project) { create(:project) }
    let(:order_attributes) { { user:, study:, project: } }

    it 'creates a persisted order' do
      expect(order).to be_persisted
    end

    it 'sets the order attributes' do
      expect(order).to have_attributes(
        user:,
        study:,
        project:
      )
    end

    context 'with a block' do
      subject(:order_with_block) do
        submission_template.create_order!(order_attributes) do |created_order|
          created_order.study = block_study
        end
      end

      let(:block_study) { create(:study) }

      it 'returns a persisted order' do
        expect(order_with_block).to be_persisted
      end

      it 'allows the block to modify the order' do
        expect(order_with_block.study).to eq(block_study)
      end
    end
  end

  describe '#create_with_submission!' do
    subject(:order) { submission_template.create_with_submission!(order_attributes) }

    let!(:request_types) { create_list(:request_type, 2, asset_type: 'Well') }
    let!(:submission_template) do
      create(:submission_template, submission_parameters: {
               request_type_ids_list: request_types.map(&:id)
             })
    end
    let!(:user) { create(:user) }
    let!(:study) { create(:study) }
    let!(:project) { create(:project) }
    let!(:plate) { create(:plate, well_count: 5) }
    let(:order_attributes) do
      {
        user: user,
        study: study,
        project: project,
        assets: plate.wells
      }
    end

    it 'creates a persisted order' do
      expect(order).to be_persisted
    end

    it 'sets the order attributes' do
      expect(order).to have_attributes(
        user: user,
        study: study,
        project: project,
        assets: plate.wells
      )
    end

    it 'creates an associated submission' do
      expect(order.submission).to be_present
    end

    it 'sets the submission user' do
      expect(order.submission.user).to eq(user)
    end
  end

  describe '#new_order' do
    subject(:order) { submission_template.new_order(order_attributes) }

    let!(:request_types) { create_list(:request_type, 2) }
    let!(:submission_template) do
      create(:submission_template, submission_parameters: {
               request_type_ids_list: request_types.map(&:id)
             })
    end
    let(:order_attributes) { { user_id: 1, study_id: 1, project_id: 1 } }

    it 'returns an order of the submission class type' do
      expect(order).to be_a(submission_template.submission_class)
    end

    it 'sets the order attributes' do
      expect(order).to have_attributes(
        user_id: 1,
        study_id: 1,
        project_id: 1,
        template_name: submission_template.name
      )
    end
  end

  describe '#submission_class' do
    it 'returns the class specified by submission_class_name' do
      submission_template = create(:submission_template, submission_class_name: 'LinearSubmission')
      expect(submission_template.submission_class).to eq(LinearSubmission)
    end
  end

  describe '#sequencing?' do
    it 'returns true if any request type is a sequencing request' do
      sequencing_request_type = create(:sequencing_request_type)
      non_sequencing_request_type = create(:request_type)
      submission_template = create(:submission_template, submission_parameters: {
                                     request_type_ids_list: [sequencing_request_type.id, non_sequencing_request_type.id]
                                   })

      expect(submission_template.sequencing?).to be true
    end

    it 'returns false if no request types have sequencing set to true' do
      request_types = create_list(:request_type, 2)
      submission_template = create(:submission_template, submission_parameters: {
                                     request_type_ids_list: request_types.map(&:id)
                                   })

      expect(submission_template.sequencing?).to be false
    end
  end

  describe '#input_asset_type' do
    it 'returns the asset type of the first request type in the list' do
      request_type1 = create(:request_type, asset_type: 'Plate')
      request_type2 = create(:request_type, asset_type: 'Tube')
      submission_template = create(:submission_template, submission_parameters: {
                                     request_type_ids_list: [request_type1.id, request_type2.id]
                                   })

      expect(submission_template.input_asset_type).to eq('Plate')
    end
  end

  describe '#input_plate_purposes' do
    it 'returns the acceptable purposes of the first request type in the list' do
      purposes = create_list(:purpose, 2)
      request_type1 = create(:request_type, asset_type: 'Plate', acceptable_purposes: purposes)
      request_type2 = create(:request_type, asset_type: 'Tube')
      submission_template = create(:submission_template, submission_parameters: {
                                     request_type_ids_list: [request_type1.id, request_type2.id]
                                   })

      expect(submission_template.input_plate_purposes).to eq(purposes)
    end
  end

  describe '#request_type_keys' do
    it 'returns the keys of the request types in the list' do
      request_type1 = create(:request_type, key: 'request_type_1')
      request_type2 = create(:request_type, key: 'request_type_2')
      submission_template = create(:submission_template, submission_parameters: {
                                     request_type_ids_list: [request_type1.id, request_type2.id]
                                   })

      expect(submission_template.request_type_keys).to eq(%w[request_type_1 request_type_2])
    end
  end
end
