# frozen_string_literal: true
RSpec.describe 'MethodBenchmarking' do
  let(:my_class) do
    Class.new do
      extend MethodBenchmarking

      # rubocop:disable Metrics/ParameterLists
      def my_method(arg_a, arg_b, _arg_c, _arg_d, _arg_e, _arg_f, arg_g)
        "#{arg_a}, #{arg_b}, #{arg_g}, #{yield}"
      end

      # rubocop:enable Metrics/ParameterLists

      benchmark_method :my_method
    end
  end

  let(:my_class_b) do
    Class.new do
      extend MethodBenchmarking

      # rubocop:disable Metrics/ParameterLists
      def my_method(arg_a, arg_b, _arg_c, _arg_d, _arg_e, _arg_f, arg_g)
        "#{arg_a}, #{arg_b}, #{arg_g}, #{yield}"
      end

      # rubocop:enable Metrics/ParameterLists

      benchmark_method :my_method, tag: 'my_tag'
    end
  end

  context 'when defining a new class that uses benchmarking' do
    context 'when calling the method' do
      let(:instance) { my_class.new }

      it 'logs the benchmarking' do
        expect(Rails.logger).to receive(:debug)
        instance.my_method(1, 2, 3, 4, 5, 6, 7) { 'ho' }
      end

      it 'runs the command as normal' do
        expect(instance.my_method(1, 2, 3, 4, 5, 6, 7) { 'hi' }).to eq('1, 2, 7, hi')
      end
    end

    context 'when defining options' do
      let(:instance) { my_class_b.new }

      it 'displays the tag' do
        expect(Rails.logger).to receive(:debug) do |msg|
          expect(msg).to match('my_tag')
        end
        instance.my_method(1, 2, 3, 4, 5, 6, 7) { 'ho' }
      end

      it 'displays the method name' do
        expect(Rails.logger).to receive(:debug) do |msg|
          expect(msg).to match('my_method')
        end
        instance.my_method(1, 2, 3, 4, 5, 6, 7) { 'ho' }
      end

      it 'displays the measurement' do
        expect(Rails.logger).to receive(:debug) do |msg|
          expect(msg).to match(/(\d\.\d+)?  (\d\.\d+)?  (\d\.\d+)?/)
        end
        instance.my_method(1, 2, 3, 4, 5, 6, 7) { 'ho' }
      end
    end
  end
end
