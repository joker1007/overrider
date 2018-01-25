RSpec.describe Overrider do
  RSpec::Matchers.define :ensure_trace_point_disable do
    match do |klass|
      klass.instance_variable_get("@__overrider_trace_point").nil? &&
        klass.instance_variable_get("@__overrider_singleton_trace_point").nil?
    end

    failure_message do
      "trace_point cleared"
    end

    failure_message_when_negated do
      "trace_point remained"
    end
  end

  context "Unless `override` method has super method" do
    it "does not raise", aggregate_failures: true do
      expect {
        class A1
          def foo
          end
        end

        class A2 < A1
          extend Overrider

          override def foo
          end
        end
      }.not_to raise_error
      expect(A2).to ensure_trace_point_disable

      expect {
        c = Class.new(A1) do
          extend Overrider

          override def foo
          end
        end
        expect(c).to ensure_trace_point_disable
      }.not_to raise_error
    end
  end

  context "Unless `override` method has no super method" do
    it "raise Overrider::NoSuperMethodError", aggregate_failures: true do
      ex = nil
      begin
        class B1
        end

        class B2 < B1
          extend Overrider

          override def foo
          end
        end
      rescue Overrider::NoSuperMethodError => e
        ex = e
      end

      expect(B2).to ensure_trace_point_disable
      expect(ex).to be_a(Overrider::NoSuperMethodError)
      expect(ex.override_class).to eq(B2)
      expect(ex.unbound_method.name).to eq(:foo)

      begin
        c = Class.new do
          extend Overrider

          override def bar
          end
        end

        expect(c).to ensure_trace_point_disable
      rescue Overrider::NoSuperMethodError => e
        ex = e
      end

      expect(ex).to be_a(Overrider::NoSuperMethodError)
      expect(ex.override_class).to be_a(Class)
      expect(ex.unbound_method.name).to eq(:bar)
    end
  end

  context "Unless `override` method has no super method but include after" do
    it "does not raise" do
      expect {
        module C1
          def foo
          end

          def bar
          end
        end

        class C2
          extend Overrider

          override def foo
          end

          include C1
        end

        Class.new do
          extend Overrider

          override def foo
          end

          pr = proc {}
          pr.call

          include C1
        end

        ex = nil
        begin
          class C3
            extend Overrider

            override def foo
            end

            raise "err"

            include C1
          end
        rescue RuntimeError => e
          ex = e
        end
        expect(ex).to be_a(RuntimeError)
      }.not_to raise_error
    end
  end

  context "Unless `override` singleton method has no super method but extend after" do
    it "raise NoSuperMethodError", aggregate_failures: true do
      ex = nil
      begin
        class D1
        end

        class D2 < D1
          extend Overrider

          class << self
            def foo
            end
          end

          override_singleton_method :foo
        end
      rescue Overrider::NoSuperMethodError => e
        ex = e
      end

      expect(D2).to ensure_trace_point_disable
      expect(ex).to be_a(Overrider::NoSuperMethodError)
      expect(ex.override_class).to eq(D2)
      expect(ex.unbound_method.name).to eq(:foo)

      begin
        c = Class.new do
          extend Overrider

          class << self
            def bar
            end
          end

          override_singleton_method :bar
        end

        expect(c).to ensure_trace_point_disable
      rescue Overrider::NoSuperMethodError => e
        ex = e
      end

      expect(ex).to be_a(Overrider::NoSuperMethodError)
      expect(ex.override_class).to be_a(Class)
      expect(ex.unbound_method.name).to eq(:bar)

      class D2_1
        def self.foo
        end
      end

      class D2_2 < D2_1
        extend Overrider

        class << self
          def foo
          end
        end

        override_singleton_method :foo
      end

      expect(D2_2).to ensure_trace_point_disable
    end
  end

  context "`override` singleton method has no super method but extend after" do
    it do
      expect {
        module E1
          def foo
          end

          def bar
          end
        end

        class E2
          extend Overrider

          class << self
            def foo
            end

            def bar
            end
          end

          override_singleton_method :foo
          override_singleton_method :bar

          extend E1
        end
        expect(E2).to ensure_trace_point_disable

        Class.new do
          extend Overrider

          class << self
            def foo
            end
          end
          override_singleton_method :foo

          pr = proc {}
          pr.call

          extend E1
        end
      }.not_to raise_error
    end
  end

  context "`override` singleton_method has super method" do
    it "does not raise" do
      expect {
        class F1
          class << self
            def foo
            end
          end
        end

        class F2 < F1
          extend Overrider

          override_singleton_method def self.foo
          end
        end

        expect(F2).to ensure_trace_point_disable
      }.not_to raise_error
    end
  end

  it "can support `class << self` and `override`. but singleton_class requires `extend` Overrider" do
    expect {
      class G1
        class << self
          def foo
          end
        end
      end

      class G2 < G1
        class << self
          extend Overrider

          override def foo
          end
        end
      end
    }.not_to raise_error
  end

  it "cannot support `class << self` and `override` and after extend module" do
    ex = nil
    begin
      module H1
        def foo
        end
      end

      class H2
        class << self
          extend Overrider

          override def foo
          end
        end

        extend H1
      end
    rescue Overrider::NoSuperMethodError => e
      ex = e
    end

    expect(ex).to be_a(Overrider::NoSuperMethodError)
  end

  it "can support `class << self` and `override` and before extend module" do
    expect {
      module I1
        def foo
        end
      end

      class I2
        extend I1
        class << self
          extend Overrider

          override def foo
          end
        end
      end
    }.not_to raise_error
  end

  it "cannot support `override` and open class at other place" do
    ex = nil
    begin
      module J1
        def foo
        end
      end

      class J2
        extend Overrider

        override def foo
        end
      end

      class J2
        include J1
      end
    rescue Overrider::NoSuperMethodError => e
      ex = e
    end

    expect(ex).to be_a(Overrider::NoSuperMethodError)
  end
end
