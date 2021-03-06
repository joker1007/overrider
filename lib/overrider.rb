require "overrider/version"
require "set"
require "ripper"

module Overrider
  class NoSuperMethodError < StandardError
    attr_reader :override_class, :unbound_method

    def initialize(klass, method, backtrace = nil)
      super("`#{method.owner}##{method.name}` requires super method.")
      @override_class = klass
      @unbound_method = method
      set_backtrace(backtrace) if backtrace
    end
  end

  class SexpTraverser
    def initialize(sexp)
      @sexp = sexp
    end

    def traverse(current_sexp = nil, parent = nil, &block)
      sexp = current_sexp || @sexp
      first = sexp[0]
      if first.is_a?(Symbol) # node
        yield sexp, parent
        args = Ripper::PARSER_EVENT_TABLE[first]
        return if args.nil? || args.zero?

        args.times do |i|
          param = sexp[i + 1]
          if param.is_a?(Array)
            traverse(param, sexp, &block)
          end
        end
      else # array
        sexp.each do |n|
          if n.is_a?(Array)
            traverse(n, sexp, &block)
          end
        end
      end
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

  def self.sexps
    @sexps ||= {}
  end

  private

  def override_methods
    @override_methods ||= Set.new
  end

  using Module.new {
    refine Module do
      def trace_for_override(owner)
        @__overrider_trace_point ||= TracePoint.trace(:end, :c_return, :return, :raise) do |t|
          if t.event == :raise
            @__overrider_trace_point.disable
            @__overrider_trace_point = nil
            next
          end

          klass = t.self

          override_at_outer = false
          if t.event == :return && klass == self && (t.method_id == :override || t.method_id == :override_singleton_method)
            c = caller_locations(2, 1)[0]
            traverser = SexpTraverser.new(Overrider.sexps[c.absolute_path])
            traverser.traverse do |n, parent|
              if n[0] == :@ident && (n[1] == "override" || n[1] == "override_singleton_method") && n[2][0] == c.lineno
                if parent[0] == :command || parent[0] == :fcall
                  # override :foo
                elsif parent[0] == :command_call || parent[0] == :call
                  if parent[1][0] == :var_ref && parent[1][1][0] == :@kw && parent[1][1][1] == "self"
                    # self.override :foo
                  else
                    # unknown case
                    warn "call `override` method by unknown way"
                    override_at_outer = true
                  end
                else
                  override_at_outer = true
                end
              end
            end
          end

          target_class_end = klass == owner && t.event == :end
          target_class_new_end = (klass == Class || klass == Module) && t.event == :c_return && t.method_id == :new && t.return_value == owner

          if target_class_end || target_class_new_end || override_at_outer
            override_methods.each do |meth|
              unless meth.super_method
                @__overrider_trace_point.disable
                @__overrider_trace_point = nil
                raise NoSuperMethodError.new(self, meth, caller(4))
              end
            end
            @__overrider_trace_point.disable
            @__overrider_trace_point = nil
          end
        end
      end
    end
  }

  def override(symbol)
    return symbol if Overrider.disabled?

    owner = self
    override_methods.add(instance_method(symbol))

    caller_info = caller_locations(1, 1)[0]
    unless Overrider.sexps[caller_info.absolute_path]
      Overrider.sexps[caller_info.absolute_path] ||= Ripper.sexp(File.read(caller_info.absolute_path))
    end

    trace_for_override(owner)

    symbol
  end

  def override_singleton_method(symbol)
    return symbol if Overrider.disabled?

    owner = self
    override_methods.add(singleton_class.instance_method(symbol))

    caller_info = caller_locations(1, 1)[0]
    unless Overrider.sexps[caller_info.absolute_path]
      Overrider.sexps[caller_info.absolute_path] ||= Ripper.sexp(File.read(caller_info.absolute_path))
    end

    trace_for_override(owner)

    symbol
  end
end
