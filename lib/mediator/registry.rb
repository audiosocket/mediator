require "mediator/errors"

class Mediator
  module Registry

    # Sugar for `register`.
    #
    #     class FooMediator < Mediator
    #       accept Foo  # same as Mediator.register FooMediator, Foo
    #     end

    def accept *subjects, &block
      register self, *subjects, &block
    end

    # Find and instantiate a mediator for `subject` by consulting
    # `map`. Returns `nil` if no mediator can be found. Inheritance is
    # respected for mediators registered by class, so:
    #
    #     A = Class.new
    #     B = Class.new A
    #     M = Class.new Mediator
    #
    #     M.subject A
    #     Mediator.for B.new  #  => A
    #
    # Mediators are searched in reverse insertion order.
    #
    # Options:
    #   context  - passed to new context
    #   registry - optional registry map to use instead of default

    def for subject, opts = {}
      context = opts[:context]

      reg = opts[:registry] ||
          (context.respond_to?(:registered_with) && context.registered_with)
      
      registry(reg).keys.reverse.each do |criteria|
        return registry[criteria].new subject, context if criteria === subject
      end

      raise Error, "Can't find a Mediator for #{subject.inspect}."
    end

    # Returns a mediator registry. If no arg is passed the default registry
    # is returned. 

    def registry reg = nil
      reg ||= :default
      reg.is_a?(Symbol) ? registries[reg] : reg
    end

    # Sugar for `for`.

    def [] subject, opts = {}
      self.for subject, opts
    end

    def registries
      @@registries ||= Hash.new { |h,k| h[k] = {} }
    end

    def registered_with registry = nil
      return @with if registry.nil?
      @with = registry
    end

    # Sugar for creating and registering a Mediator subclass.

    def mediate *subjects, &block
      mediator = Class.new self, &block
      register mediator, *subjects
    end

    # Register a Mediator subclass's interest in one or more subject
    # classes. If more detailed selection behavior is necessary,
    # `subject` can take a block instead. When the mediator for a
    # subject is discovered with `Mediator.for` the given block will be
    # passed the subject and can return `true` or `false`.
    # Can take an optional hash specifying what to register the mediator with.

    def register mklass, *subjects, &block
      opts = subjects.last.is_a?(Hash) ? subjects.pop : {}
      reg_map = registry opts[:registry]

      if block_given?
        unless subjects.empty?
          raise ArgumentError, "Can't provide both a subject and a block."
        end

        reg_map[block] = mklass
        mklass.registered_with(reg_map) if mklass.respond_to? :registered_with
      end

      subjects.each do |k|
        reg_map[k] = mklass
        mklass.registered_with(reg_map) if mklass.respond_to? :registered_with
      end

      mklass
    end
  end
end
