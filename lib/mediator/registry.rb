require "mediator/errors"
require "ostruct"

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
      # Return a dummy mediator is subject is nil
      # (can happen with r.one :foo, empty: true)

      return OpenStruct.new render: nil if subject == nil

      context = opts[:context]

      reg = registry(opts[:registry] || context)

      reg.keys.reverse.each do |criteria|
        return reg[criteria].new subject, context if criteria === subject
      end

      raise Error, "Can't find a Mediator for #{subject.inspect}."
    end

    # Returns a mediator registry. If no arg is passed the default registry
    # is returned. Keys can be either a symbol or a Mediator instance or class

    def registry key = nil

      # If key exists then see if we've got an entry already and if
      # not force the key to be a symbol, i.e. :default, :accounting, etc.
      
      if key
        return registries[key.class] if registries.key?(key.class)
        return registries[key] if registries.key?(key)
        key = :default unless key.is_a?(Symbol)
      end
      
      key ||= :default
      registries[key] ||= {}
    end

    # Sugar for `for`.

    def [] subject, opts = {}
      self.for subject, opts
    end

    # Stores a map of all the different registries.
    #  - keys are registry symbols, i.e. :default, :account, or mediators
    #  - values are a simple map
    
    def registries
      @@registries ||= Hash.new
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
        registries[mklass] = reg_map
      end

      subjects.each do |k|
        reg_map[k] = mklass
        registries[mklass] = reg_map
      end

      mklass
    end
  end
end
