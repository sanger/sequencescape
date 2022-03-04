# frozen_string_literal: true

shared_examples 'an automated order' do
  context 'with a cross study/project tube' do
    let(:aliquots) { create_list :tagged_aliquot, 2 }

    it 'does not set study' do
      subject.valid?
      expect(subject.study).to be_nil
    end

    it 'does not set project' do
      subject.valid?
      expect(subject.project).to be_nil
    end
  end

  context 'with a single study/project tube' do
    let(:aliquots) { create_list :tagged_aliquot, 2, study: study, project: project }

    it { is_expected.to be_valid }

    it 'sets study to the aliquots study' do
      subject.valid?
      expect(subject.study).to eq study
    end

    it 'sets project to the aliquots project' do
      subject.valid?
      expect(subject.project).to eq project
    end

    context 'with two single study/project assets in different studies' do
      let(:assets) { [tube, other_tube] }
      let(:other_tube) { create :multiplexed_library_tube, aliquots: other_aliquots }
      let(:other_aliquots) { create_list :tagged_aliquot, 1 }

      it { is_expected.not_to be_valid }
    end
  end
end
