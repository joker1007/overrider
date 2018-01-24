RSpec.describe Overrider do
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

      expect {
        Class.new(A1) do
          extend Overrider

          override def foo
          end
        end
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

      expect(ex).to be_a(Overrider::NoSuperMethodError)
      expect(ex.override_class).to eq(B2)
      expect(ex.unbound_method.name).to eq(:foo)

      begin
        Class.new do
          extend Overrider

          override def bar
          end
        end
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
        end

        class C2
          extend Overrider

          override def foo
          end

          include C1
        end
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

      expect(ex).to be_a(Overrider::NoSuperMethodError)
      expect(ex.override_class).to eq(D2)
      expect(ex.unbound_method.name).to eq(:foo)

      begin
        Class.new do
          extend Overrider

          class << self
            def bar
            end
          end

          override_singleton_method :bar
        end
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
