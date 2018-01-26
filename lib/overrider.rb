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

  @disable = false

  def self.disable=(v)
    @disable = v
  end

  def self.disabled?
    @disable
  end

  def self.enabled?
    !disabled?
  end

  private

  def override(symbol)
    return if Overrider.disabled?

    @__overrider_trace_point ||= TracePoint.trace(:end, :c_return, :raise) do |t|
      if t.event == :raise
        @__overrider_trace_point.disable
        @__overrider_trace_point = nil
        next
      end

      klass = t.self
      target_end_event = klass == self && t.event == :end
      target_c_return_event = (klass == Class || klass == Module) && t.event == :c_return && t.method_id == :new
      if target_end_event || target_c_return_event
        @ensure_overrides.each do |n|
          meth = self.instance_method(n)
          unless meth.super_method
            @__overrider_trace_point.disable
            @__overrider_trace_point = nil
            raise NoSuperMethodError.new(self, meth)
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
    return if Overrider.disabled?

    @__overrider_singleton_trace_point ||= TracePoint.trace(:end, :c_return, :raise) do |t|
      if t.event == :raise
        @__overrider_singleton_trace_point.disable
        @__overrider_singleton_trace_point = nil
        next
      end

      klass = t.self
      target_end_event = klass == self && t.event == :end
      target_c_return_event = (klass == Class || klass == Module) && t.event == :c_return && t.method_id == :new
      if target_end_event || target_c_return_event
        @ensure_overrides.each do |n|
          meth = self.singleton_class.instance_method(n)
          unless meth.super_method
            @__overrider_singleton_trace_point.disable
            @__overrider_singleton_trace_point = nil
            raise NoSuperMethodError.new(self, meth)
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
