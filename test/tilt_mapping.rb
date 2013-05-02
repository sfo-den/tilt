require 'test_helper'
require 'tilt'
require 'tilt/mapping'

module Tilt

  class MappingTest < MiniTest::Unit::TestCase
    class Stub
    end

    setup do
      @mapping = Mapping.new
    end

    test "registered?" do
      @mapping.register(Stub, 'foo', 'bar')
      assert @mapping.registered?('foo')
      assert @mapping.registered?('bar')
      refute @mapping.registered?('baz')
    end

    test "lookups on registered" do
      @mapping.register(Stub, 'foo', 'bar')
      assert_equal Stub, @mapping['foo']
      assert_equal Stub, @mapping['bar']
      assert_equal Stub, @mapping['hello.foo']
      assert_nil @mapping['foo.baz']
    end

    context "lazy with one template class" do
      setup do
        @mapping.register_lazy('MyTemplate', 'my_template', 'mt')
      end

      test "registered?" do
        assert @mapping.registered?('mt')
      end

      test "basic lookup" do
        req = proc do |file|
          assert_equal 'my_template', file
          class ::MyTemplate; end
          true
        end

        @mapping.stub :require, req do
          klass = @mapping['hello.mt']
          assert_equal ::MyTemplate, klass
        end

        Object.send :remove_const, :MyTemplate
      end

      test "doesn't require when template class is present" do
        class ::MyTemplate; end

        req = proc do |file|
          flunk "#require shouldn't be called"
        end

        @mapping.stub :require, req do
          klass = @mapping['hello.mt']
          assert_equal ::MyTemplate, klass
        end

        Object.send :remove_const, :MyTemplate
      end

      test "raises NameError when the class name is defined" do
        req = proc do |file|
          # do nothing
        end

        @mapping.stub :require, req do
          assert_raises(NameError) do
            @mapping['hello.mt']
          end
        end
      end
    end

    context "lazy with two template classes" do
      setup do
        @mapping.register_lazy('MyTemplate1', 'my_template1', 'mt')
        @mapping.register_lazy('MyTemplate2', 'my_template2', 'mt')
      end

      test "registered?" do
        assert @mapping.registered?('mt')
      end

      test "only attempt to load the last template" do
        req = proc do |file|
          assert_equal 'my_template2', file
          class ::MyTemplate2; end
          true
        end

        @mapping.stub :require, req do
          klass = @mapping['hello.mt']
          assert_equal ::MyTemplate2, klass
        end

        Object.send :remove_const, :MyTemplate2
      end

      test "falls back when LoadError is thrown" do
        req = proc do |file|
          raise LoadError unless file == 'my_template1'
          class ::MyTemplate1; end
          true
        end

        @mapping.stub :require, req do
          klass = @mapping['hello.mt']
          assert_equal ::MyTemplate1, klass
        end

        Object.send :remove_const, :MyTemplate1
      end

      test "raises the first LoadError when everything fails" do
        req = proc do |file|
          raise LoadError, file
        end

        @mapping.stub :require, req do
          err = assert_raises(LoadError) do
            klass = @mapping['hello.mt']
          end

          assert_equal 'my_template2', err.message
        end
      end
    end

    test "raises NameError on invalid class name" do
      @mapping.register_lazy '#foo', 'my_template', 'mt'

      req = proc do |file|
        # do nothing
      end

      @mapping.stub :require, req do
        assert_raises(NameError) do
          @mapping['hello.mt']
        end
      end
    end
  end
end
