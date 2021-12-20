# frozen_string_literal: true

require 'test_helper'

class SwipecardTest < ActiveSupport::TestCase
    attr_reader :options, :label, :swipecard_label

    def setup
        @options = { swipecard: 'test-swipecard', user_login: 'test-user' }
        @label = {
            top_left: options[:user_login],
            barcode: options[:swipecard],
            label_name: 'main_label'
        }
        @swipecard_label = LabelPrinter::Label::Swipecard.new(options)
    end

    test 'build_label should create the correct label layout' do
        assert_equal label, swipecard_label.build_label
    end

    test 'labels should return an array with a single label' do
        assert_equal [label], swipecard_label.labels
    end
end
