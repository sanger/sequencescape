# frozen_string_literal: true

require 'rails_helper'

describe SubmissionsHelper do
  describe '#field_input_tag' do
    let(:field_info) do
      double(
        kind: 'Selection',
        key: :ot_recipe,
        selection: %w[Free Flex],
        default_value: 'Free',
        required: true
      )
    end

    let(:wafer_size_field_info) do
      double(
        kind: 'Selection',
        key: :wafer_size,
        selection: %w[5TB 10TB],
        default_value: '10TB',
        required: true
      )
    end

    it 'uses the default value for selection fields when no request option is set' do
      html = helper.field_input_tag(field_info, values: {}, name_format: 'submission[order_params][%s]')

      expect(html).to include('<option selected="selected" value="Free">Free</option>')
    end

    it 'uses the default value for selection fields when request option is blank' do
      html = helper.field_input_tag(field_info, values: { ot_recipe: '' }, name_format: 'submission[order_params][%s]')

      expect(html).to include('<option selected="selected" value="Free">Free</option>')
    end

    it 'uses the default wafer_size when request option is blank' do
      html = helper.field_input_tag(wafer_size_field_info,
                                    values: { wafer_size: '' },
                                    name_format: 'submission[order_params][%s]')

      expect(html).to include('<option selected="selected" value="10TB">10TB</option>')
    end
  end
end
