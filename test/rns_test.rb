require 'minitest/autorun'
require 'rns'

class RnsTest < MiniTest::Unit::TestCase
  Math = Rns do
    def inc(n)
      n + 1
    end

    def dec(n)
      n - 1
    end
  end

  def test_functions_function
    m = Rns do
      def add(a, b)
        a + b
      end

      def inc(a)
        add a, 1
      end

      def dec_block
        add yield(), -1
      end
    end

    assert_equal 42, m.add(20, 22)
    assert_equal 2, m.inc(1)
    assert_equal 11, m.dec_block { 12 }
  end

  def test_private_functions
    m = Rns do
      def whoa_dave
        whoa "Dave"
      end
    private
      def whoa(dude)
        "Whoa, #{dude}, totally awesome wave"
      end
    end

    assert_equal "Whoa, Dave, totally awesome wave", m.whoa_dave
    assert_raises NoMethodError do
      m.whoa "Man"
    end
  end

  def test_ivars_cant_be_set
    m = Rns do
      def set_ivar
        @ivar = "something"
      end
    end

    assert_raises_frozen_error do
      m.set_ivar
    end
    assert_raises_frozen_error do
      m.instance_variable_set :@ivar, "something"
    end
  end

  def test_cvars_cant_be_set
    m = Rns do
      def set_cvar
        @@cvar = "something"
      end
    end

    # this fails on 1.8.7
    assert_raises_frozen_error do
      m.set_cvar
    end
  end

  def test_importing_namespaces
    ns = Rns(Math) do
      def double_inc(n)
        inc inc(n)
      end
    end

    assert_equal 3, ns.double_inc(1)
  end

  def test_importing_namespace_functions
    ns = Rns(Math => [:dec]) do
      def double_inc(n)
        inc inc(n)
      end

      def double_dec(n)
        dec dec(n)
      end
    end

    assert_equal -1, ns.double_dec(1)
    assert_raises NoMethodError do
      ns.double_inc(1)
    end
  end

  def test_imported_methods_arent_public
    ns = Rns(Math => [:dec]) do
    end

    assert_raises NoMethodError do
      ns.dec(1)
    end
  end

private

  def assert_raises_frozen_error
    yield
  rescue RuntimeError, TypeError => e
    assert_match /can't modify/i, e.message
  else
    flunk "Frozen object exception expected"
  end

end