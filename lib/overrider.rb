require "overrider/version"
require 'set'

module Overrider
  class NoSuperMethodError < StandardError
    attr_reader :override_class, :unbound_method

    def initialize(klass, method)
      super("#{method} requires super method.")
      @override_class = klass
      @unbound_method = method
    end
  end

  private

  def override(symbol)
    caller_info = caller_locations(1, 1)[0]
    event_type = if caller_info.label.match?(/block/)
      :b_return
    else
      :end
    end

    @__overrider_trace_point ||= TracePoint.trace(event_type) do |t|
      klass = t.self
      if klass == self
        @ensure_overrides.each do |n|
          meth = klass.instance_method(n)
          unless meth.super_method
            @__overrider_trace_point.disable
            @__overrider_trace_point = nil
            raise NoSuperMethodError.new(klass, meth)
          end
        end
        @__overrider_trace_point.disable
        @__overrider_trace_point = nil
      end
    end
    @ensure_overrides ||= Set.new
    @ensure_overrides.add(symbol)
    symbol
  end

  def override_singleton_method(symbol)
    caller_info = caller_locations(1, 1)[0]
    event_type = if caller_info.label.match?(/block/)
      :b_return
    else
      :end
    end

    @__overrider_singleton_trace_point ||= TracePoint.trace(event_type) do |t|
      klass = t.self
      if klass == self
        @ensure_overrides.each do |n|
          meth = klass.singleton_class.instance_method(n)
          unless meth.super_method
            @__overrider_singleton_trace_point.disable
            @__overrider_singleton_trace_point = nil
            raise NoSuperMethodError.new(klass, meth)
          end
        end
        @__overrider_singleton_trace_point.disable
        @__overrider_singleton_trace_point = nil
      end
    end
    @ensure_overrides ||= Set.new
    @ensure_overrides.add(symbol)
    symbol
  end
end
