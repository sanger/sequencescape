RSpec.describe 'MethodBenchmarking' do
  context 'when defining a new class that uses benchmarking' do
    class MyClass
      include MethodBenchmarking

      def my_method(a, b, c, d, e, f, g, &block)
        "#{a}, #{b}, #{g}, #{yield}"
      end
      benchmark_method :my_method
    end

    context 'when calling the method' do
      let(:instance) { MyClass.new }
      it 'logs the benchmarking' do
        expect(Rails.logger).to receive(:debug)
        instance.my_method(1,2,3,4,5,6,7) {"ho"}
      end
      it 'runs the command as normal' do
        expect(instance.my_method(1,2,3,4,5,6,7) { "hi" }).to eq("1, 2, 7, hi")
      end
    end

    context 'when defining options' do
      class MyClassB
        include MethodBenchmarking
  
        def my_method(a, b, c, d, e, f, g, &block)
          "#{a}, #{b}, #{g}, #{yield}"
        end
        benchmark_method :my_method, tag: 'my_tag', project_name: 'sequencescape', exclude_callback_patterns: ['patterns']
      end
      let(:instance) { MyClassB.new }
      it 'displays the tag' do
        expect(Rails.logger).to receive(:debug) do |msg|
          expect(msg).to match('my_tag')
        end
        instance.my_method(1,2,3,4,5,6,7) {"ho"}
      end

      it 'displays the method name' do
        expect(Rails.logger).to receive(:debug) do |msg|
          expect(msg).to match('my_method')
        end
        instance.my_method(1,2,3,4,5,6,7) {"ho"}
      end

      it 'displays the measurement' do 
        expect(Rails.logger).to receive(:debug) do |msg|
          expect(msg).to match(/(\d\.\d+)?  (\d\.\d+)?  (\d\.\d+)?/)
        end
        instance.my_method(1,2,3,4,5,6,7) {"ho"}
      end
    end
  end
end