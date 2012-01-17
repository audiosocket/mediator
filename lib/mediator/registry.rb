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

    def for subject, context = nil
      map.keys.reverse.each do |criteria|
        return map[criteria].new subject, context if criteria === subject
      end

      raise Error, "Can't find a Mediator for #{subject.inspect}."
    end

    # Sugar for `for`.

    def [] subject, context = nil
      self.for subject, context
    end

    # A map from subject class or block to Mediator subclass.

    def map
      @@map ||= {}
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

    def register mklass, *subjects, &block
      if block_given?
        unless subjects.empty?
          raise ArgumentError, "Can't provide both a subject and a block."
        end

        map[block] = mklass
      end

      subjects.each { |k| map[k] = mklass }

      mklass
    end
  end
end
