require "mediator"
require "minitest/autorun"
require "ostruct"

describe Mediator do
  before do
    Mediator.registries.clear
  end

  describe "initialization" do
    it "takes a subject and a context" do
      m = Mediator.new :subject, :context

      assert_equal :context, m.context
      assert_equal :subject, m.subject
    end

    it "optionally takes a parent context" do
      m = Mediator.new :s, :c
      n = Mediator.new :t, m

      assert_equal :c, n.context
      assert_equal m, n.parent
    end
  end

  describe "nesting" do
    it "is inside another mediator when a parent exists" do
      m = Mediator.new :s, :c

      refute m.nested?
      assert Mediator.new(:s, m).nested?
    end

    it "can test if it is nested inside a specific parent's subject." do
      m = OpenStruct.new bar: "gni"
      n = Mediator.new m, :t
      o = Mediator.new :u, n

      refute n.nested? m
      assert o.nested? m
      assert o.nested? OpenStruct
    end

    it "can test up in inheritance tree." do
      m = OpenStruct.new bar: "gni"
      n = Mediator.new m, :t
      o = Mediator.new :u, n
      v = Mediator.new :u, o

      assert v.nested? m
    end

    it "accepts an arbitrary block to test against parent." do
      m = OpenStruct.new bar: "gni"
      n = Mediator.new m, :t
      o = Mediator.new :u, n

      refute o.nested? { |p| p.subject.bar == "gno" }
      assert o.nested? { |p| p.subject.bar == "gni" }
    end

    it "can narrow inside? by checking subjects" do
      m = Mediator.new :s, :c
      n = Mediator.new :t, m
      o = Mediator.new :u, n

      assert n.inside? :s
      assert o.inside? :s
    end
  end

  describe "parsing" do
    it "raises NotImplementedError by default" do
      m = Mediator.new :subject

      assert_raises NotImplementedError do
        m.parse :data
      end
    end

    it "builds a Parser and delegates to parse!" do
      c = Class.new Mediator do
        def parse! p
          p.key :foo
        end
      end

      s = OpenStruct.new
      m = c.new s

      m.parse foo: :bar
      assert_equal :bar, s.foo
    end

    it "always returns the subject" do
      c = Class.new Mediator do
        def parse! p
        end
      end

      m = c.new :subject
      assert_equal :subject, m.parse(:data)
    end

    it "can define a custom parser" do
      c = Class.new Mediator do
        def parse! p
          p.poke
        end

        def parser data
          p = Struct.new(:subject) do
            def poke
              subject.poked = true
            end
          end

          p.new subject
        end
      end

      s = OpenStruct.new
      m = c.new s

      m.parse nil
      assert s.poked
    end
  end

  describe "getting values from the subject" do
    it "calls a getter by default" do
      s = OpenStruct.new foo: :bar
      m = Mediator.new s

      assert_equal :bar, m.get(:foo)
    end

    it "can construct missing values if told to" do
      c = Class.new Mediator do
        def construct name
          "HELLO" if :foo == name
        end
      end

      m = c.new OpenStruct.new
      assert_equal "HELLO", m.get(:foo, construct: true)
    end
  end

  describe "setting values on the subject" do
    it "calls a setter by default" do
      s = OpenStruct.new
      m = Mediator.new s

      m.set :foo, :bar
      assert_equal :bar, s.foo
    end

    it "can transform incoming values" do
      c = Class.new Mediator do
        def setting name, value
          case value
          when String then value.upcase
          else value
          end
        end
      end

      s = OpenStruct.new
      m = c.new s

      m.set :foo, "bar"
      assert_equal "BAR", s.foo
    end
  end

  describe ".accept" do
    it "is just subclass sugar for .register" do
      c = Class.new Mediator
      c.accept Symbol

      assert_instance_of c, Mediator[:foo]
    end
  end

  describe ".for" do
    it "gets a mediator by class" do
      c = Class.new Mediator
      Mediator.register c, Symbol

      m = Mediator.for :foo

      assert_instance_of c, m
    end

    it "gets a mediator for a subclass" do
      x = Class.new
      y = Class.new x

      c = Class.new Mediator
      Mediator.register c, x

      m = Mediator.for y.new

      assert_instance_of c, m
    end

    it "gets a mediator by block eval" do
      c = Class.new Mediator

      Mediator.register c do |s|
        "hello" == s
      end

      assert_instance_of c, Mediator.for("hello")
    end

    it "is also available as []" do
      c = Class.new Mediator
      Mediator.register c, Symbol

      assert_instance_of c, Mediator[:foo]
    end

    it "raises when there's no mediator" do
      ex = assert_raises Mediator::Error do
        Mediator.for :foo
      end

      assert_equal "Can't find a Mediator for :foo.", ex.message
    end
  end

  describe ".mediate" do
    it "is just sugar for subclass creation and registration" do
      A = Class.new OpenStruct
      B = Class.new A

      c = Class.new Mediator do
        accept A

        def parse! p
          p.key :foo
        end
      end

      c.mediate B do
        def parse! p
          super
          p.key :bar
        end
      end

      i = B.new

      Mediator[i].parse foo: "foo", bar: "bar"

      assert_equal "foo", i.foo
      assert_equal "bar", i.bar
    end
  end

  describe ".register" do
    it "can register a class" do
      c = Class.new Mediator
      Mediator.register c, Symbol

      assert_equal c, Mediator.registry[Symbol]
    end

    it "can register multiple classes" do
      c = Class.new Mediator
      Mediator.register c, String, Symbol

      assert_equal c, Mediator.registry[String]
      assert_equal c, Mediator.registry[Symbol]
    end

    it "can register with a block" do
      c = Class.new Mediator
      Mediator.register(c) { |s| Symbol === s }

      b = Mediator.registry.keys.first
      refute_nil b

      assert b[:foo]
      refute b["bar"]
    end

    it "doesn't allow classes and a block to be mixed" do
      ex = assert_raises ArgumentError do
        Mediator.register :whatev, String do
          # ...
        end
      end

      assert_equal "Can't provide both a subject and a block.", ex.message
    end

    it "allows for alternate registry" do
      c = Class.new Mediator
      assert_equal c, Mediator.register(c, String, registry: :monkeys )

      r = c.registries[:monkeys]
      refute_nil r

      assert_equal c, r[String]
      assert_equal r, c.registry(c)
      assert_equal r, c.registries[c]
    end

    it "returns the registered thing" do
      c = Class.new Mediator
      assert_equal c, Mediator.register(c, String)
    end

  end
end
