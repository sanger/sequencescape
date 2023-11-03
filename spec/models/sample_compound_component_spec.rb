# frozen_string_literal: true

RSpec.describe SampleCompoundComponent, :cardinal do
  describe '#validate' do
    let(:compound_sample) { create(:sample) }
    let(:component_sample) { create(:sample) }
    let(:another_sample) { create(:sample) }

    # let variables are lazy loaded and we always want the relationship to exist
    # even if we don't access the compound sample in the test.
    before do
      compound_sample.update(component_samples: [component_sample])
      component_sample.reload
    end

    context 'when another sample becomes a compound sample of our compound sample' do
      it 'fails to validate when the new sample adopts our compound sample as a component' do
        expect { another_sample.component_samples << compound_sample }.to raise_error(
          ActiveRecord::RecordInvalid,
          /Component sample cannot have further component samples./
        )
      end

      it 'fails to validate when our compound sample adopts the new sample as a compound' do
        expect { compound_sample.compound_samples << another_sample }.to raise_error(
          ActiveRecord::RecordInvalid,
          /Component sample cannot have further component samples./
        )
      end
    end

    context 'when another sample becomes a component sample of our component sample' do
      it 'fails to validate when the new sample adopts our component sample as a compound' do
        expect { another_sample.compound_samples << component_sample }.to raise_error(
          ActiveRecord::RecordInvalid,
          /Compound sample cannot have further compound samples./
        )
      end

      it 'fails to validate when our component sample adopts the new sample as a component' do
        expect { component_sample.component_samples << another_sample }.to raise_error(
          ActiveRecord::RecordInvalid,
          /Compound sample cannot have further compound samples./
        )
      end
    end
  end
end
