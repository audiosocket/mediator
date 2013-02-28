require "mediator/errors"
require "mediator/parser"
require "mediator/registry"
require "mediator/renderer"

# Can't we all just get along? Mediators should subclass and implement
# `parse!` and `render!`.

class Mediator
  extend Registry

  # State information availble during `parse` and `render`. This is
  # often an application-specific object that provides authentication
  # and authorization data, but it can be just about anything.

  attr_reader :context

  # An optional parent mediator. Used during nested mediation: See
  # `obj`, etc.

  attr_reader :parent

  # The subject of this mediation. A rich(er) domain object that needs
  # to be translated back and forth.

  attr_reader :subject

  # Create a new mediator with a `subject` and a mediation
  # `context`. If the context is a Mediator, it will be set as this
  # instance's parent and its context will be reused.

  def initialize subject, context = nil
    @context = context
    @subject = subject

    if Mediator === context
      @parent  = @context
      @context = @parent.context
    end
  end

  # Called during `get` if `subject` doesn't have a value for `name`
  # during parsing. Subclasses can override to provide factories for
  # dependent attributes. The default implementation returns `nil`.

  def construct name
  end

  # Called before passing `data` to `parse`. Subclasses can override
  # to transform raw incoming data. The default implementation returns
  # `data` unchanged.

  def incoming data
    data
  end

  # Is `subject` the subject of one of the ancestral mediators?

  def inside? subject
    parent && (parent.subject == subject || parent.inside?(subject))
  end

  # Is this mediator nested inside a `parent`?

  def nested? candidate = nil, &block
    if candidate && block
      raise Error, "Can't provide both a candidate and a block."
    end

    if !parent
      false
    elsif !candidate && !block
      true
    elsif candidate  && (candidate === parent.subject)
      true
    elsif block && block[parent]
      true
    else
      parent.nested? candidate, &block
    end
  end

  # Called after rendering. Subclasses can override to transform raw
  # outgoing data. The default implementation returns `data`
  # unchanged.

  def outgoing data
    data
  end

  # Folds, spindles, and mutilates `data`, then applies to `subject`
  # and returns it. Subclasses should generally override `parse!`
  # instead of this method.

  def parse data
    parse! parser incoming data
    subject
  end

  # The actual parse implementation. Subclasses should override and
  # consistently call `super`.

  def parse! parser
    raise NotImplementedError
  end

  # Construct a parser instance for `data`. The parser will be passed
  # to the Mediator's `parse!` method. The default implementation
  # returns a new instance of Mediator::Parser.

  def parser data
    Mediator::Parser.new self, data
  end

  # Create a more primitive representation of `subject`. Subclasses
  # should generally override `render!` instead of this method.

  def render
    r = renderer
    render! r

    outgoing r.data
  end

  # The actual render implementation. Subclasses should override and
  # consistently call `super`.

  def render! renderer
    raise NotImplementedError
  end

  # Construct a renderer instance. The renderer will be passed to the
  # Mediator's `render!` method. The default implementation returns a
  # new instance of Mediator::Renderer.

  def renderer
    Mediator::Renderer.new self
  end

  # True if subject can construct a value for name

  def subject_has? name
    subject.respond_to?(name) || subject.respond_to?(name.to_s)
  end

  # True if data can return a value for name
  
  def data_has? data, name
    data.has_key?(name) || data.has_key?(name.to_s)
  end

  # Gets the `name` property from `subject`. The default
  # implementation calls the `name` method if it exists.

  def get name, options = {}
    value = subject.send name if subject.respond_to? name
    value = construct name    if value.nil? and options[:construct]

    getting name, value       unless value.nil?
  end

  # Called when getting `name` from `subject`. Can be used to
  # transform outgoing values, e.g., turning Time objects into epoch
  # seconds. The default implementation returns `value` unchanged.

  def getting name, value
    value
  end

  # Set `name` to `value` on `subject`. The default implementation
  # calls a matching mutator method.

  def set name, value
    subject.send "#{name}=", setting(name, value)
  end

  # Called when setting `name` to `value` on `subject`. Can be used to
  # transform incoming values, e.g., trimming all strings. The default
  # implementation returns `value` unchanged.

  def setting name, value
    value
  end
end
