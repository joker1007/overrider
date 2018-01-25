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

  using Module.new {
    refine Module do
      def detect_event_type
        caller_info = caller_locations(2, 1)[0]
        if caller_info.label.match?(/block/)
          [:b_call, :b_return, :raise]
        else
          [:end, :raise]
        end
      end
    end
  }

  def override(symbol)
    event_type = detect_event_type

    block_count = 1
    @__overrider_trace_point ||= TracePoint.trace(*event_type) do |t|
      if t.event == :raise
        @__overrider_trace_point.disable
        @__overrider_trace_point = nil
        next
      end

      block_count += 1 if t.event == :b_call
      block_count -= 1 if t.event == :b_return

      klass = t.self
      if klass == self && (t.event == :end || t.event == :b_return && block_count.zero?)
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
    event_type = detect_event_type

    block_count = 1
    @__overrider_singleton_trace_point ||= TracePoint.trace(*event_type) do |t|
      if t.event == :raise
        @__overrider_singleton_trace_point.disable
        @__overrider_singleton_trace_point = nil
        next
      end

      block_count += 1 if t.event == :b_call
      block_count -= 1 if t.event == :b_return

      klass = t.self
      if klass == self && (t.event == :end || t.event == :b_return && block_count.zero?)
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
