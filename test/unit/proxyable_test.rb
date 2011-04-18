require "test_helper"

class ProxyableTest < ActiveSupport::TestCase
  context Proxyable::ClassMethods do
    setup do
      @object = Object.new
      @object.extend(Proxyable::ClassMethods)
    end

    context '#load_proxy_list' do
      should 'do nothing if list is empty' do
        @object.load_proxy_list([])
      end

      should 'do nothing if first proxy loaded and not forcing' do
        proxy = mock('Proxy')
        proxy.expects(:loaded?).returns(true)

        @object.load_proxy_list([ proxy ], :force => false)
      end

      context 'loading objects' do
        setup do
          # Note the misordering here to ensure that the correct object is set
          @proxies = [ mock('Proxy 1', :id => 1),  mock('Proxy 2', :id => 2)  ]
          @objects = [ mock('Object 2', :id => 2), mock('Object 1', :id => 1) ]
          @proxies.first.expects(:set_object).with(@objects.last)
          @proxies.last.expects(:set_object).with(@objects.first)

          @options = {}
        end

        teardown do
          expected_options = @options.dup
          expected_options.delete(:force)
          @object.expects(:find).with([ 1, 2 ], expected_options).returns(@objects)

          @object.load_proxy_list(@proxies, @options)
        end

        should 'happen if the first proxy is loaded and forcing' do
          @proxies.first.expects(:loaded?).returns(true)
          @options[ :force ] = true
        end

        should 'happen if the first proxy is not loaded' do
          @proxies.first.expects(:loaded?).returns(false)
          @options[ :force ] = false
        end

        should 'happen if the first proxy is not loaded and force is unspecified' do
          @proxies.first.expects(:loaded?).returns(false)
        end

        should 'pass options to find' do
          @proxies.first.expects(:loaded?).returns(false)
          @options[ :include ] = :foo
        end
      end
    end
  end
end
