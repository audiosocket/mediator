require "mediator"
require "mediator/parser"
require "minitest/autorun"
require "ostruct"

describe Mediator::Parser do
  before do
    Mediator.registries.clear

    @subject  = OpenStruct.new
    @mediator = Mediator.new @subject
  end

  it "has data" do
    p = Mediator::Parser.new :mediator, :data
    assert_equal :data, p.data
  end

  it "has default data" do
    assert_equal Hash.new, Mediator::Parser.new(:mediator).data
  end

  describe "id" do
    it "translates name to subject.name_id" do
      p = Mediator::Parser.new @mediator, foo: 42

      p.id :foo
      assert_equal 42, @subject.foo_id
    end

    it "Does nothing with empty values by default" do
      p = Mediator::Parser.new @mediator, foo: ""
      @subject.foo_id = 42

      p.id :foo
      assert_equal 42, @subject.foo_id
    end

    it "Accept empty values if told to" do
      p = Mediator::Parser.new @mediator, foo: ""

      p.id :foo, empty: true
      assert_equal "", @subject.foo_id
    end
  end

  describe "ids" do
    it "translates name to subject.name_ids" do
      p = Mediator::Parser.new @mediator, foo: [5, 6, 7]

      p.ids :foo
      assert_equal [5, 6, 7], @subject.foo_ids
    end

    it "removes plurial" do
      p = Mediator::Parser.new @mediator, foos: [5, 6, 7]

      p.ids :foos
      assert_equal [5, 6, 7], @subject.foo_ids
    end

    it "can be clever with plurial if told to" do
      p = Mediator::Parser.new @mediator, boxen: [5, 6, 7]

      p.ids :box, from: :boxen
      assert_equal [5, 6, 7], @subject.box_ids
    end
  end

  describe "key" do
    before do
      @data = {
        emptystring: "", emptyarray: [], isnil: nil,
        somevalue: :gni, predicate: true, othernil: nil
      }
      @parser = Mediator::Parser.new @mediator, @data
    end

    it "parses some values" do
      @parser.key :somevalue

      assert_equal :gni, @subject.somevalue
    end

    it "sets unconditionally with empty: true and data holds an empty value for that key." do
      @subject.othernil = :not_nil

      assert @data.has_key?(:othernil)
      @parser.key :othernil, empty: true
      assert_nil @subject.othernil
    end

    it "does not touch a key with empty: true when data does not have that key defined." do
      @subject.foo = :foo

      refute @data.has_key?(:foo)
      @parser.key :foo, empty: true
      assert_equal :foo, @subject.foo
    end

    it "removes trailing '?' from predicates" do
      @parser.key :predicate?
      assert @subject.predicate
    end

    it "can pull from the options hash" do
      @parser.key :foo, value: :bar
      assert_equal :bar, @subject.foo
    end

    it "ignores empty values" do
      @parser.key :emptystring
      assert_nil @subject.emptystring

      @parser.key :emptyarray
      assert_nil @subject.emptyarray
    end

    it "ignores nil values" do
      @parser.key :isnil
      assert_nil @subject.isnil # heh
    end

    it "ignores nil or empty values returned by blocks" do
      @parser.key(:somevalue) { |p| nil }
      assert_nil @subject.foo # heh
    end
  end

  describe "key with actual data" do
    it "grabs from data like it's a Hash" do
      p = Mediator::Parser.new @mediator, foo: "bar"
      p.key :foo

      assert_equal "bar", @subject.foo
    end

    it "works with strings and symbols" do
      p = Mediator::Parser.new @mediator, "foo" => "bar"
      p.key :foo

      assert_equal "bar", @subject.foo
    end

    it "transforms values with a block" do
      p = Mediator::Parser.new @mediator, foo: "bar"
      p.key(:foo) { |d| d.upcase }

      assert_equal "BAR", @subject.foo
    end

    it "can declaratively alias a name with :from" do
      p = Mediator::Parser.new @mediator, quux: "bar"
      p.key :foo, from: :quux

      assert_equal "bar", @subject.foo
    end
  end

  describe "one" do
    before do
      Top  = Class.new OpenStruct
      Nest = Class.new OpenStruct

      Class.new Mediator do
        accept Top

        def parse! p
          p.key :foo
          p.one :nest
        end
      end

      Class.new Mediator do
        accept Nest

        def parse! p
          p.key :baz
          p.key :quux
        end
      end
    end

    it "delegates to a nested mediator" do
      s = Top.new
      s.nest = Nest.new

      m = Mediator[s]
      d = { foo: "foo!", nest: { baz: "baz!", quux: "quux!" } }

      m.parse d

      assert_equal d[:foo],         s.foo
      assert_equal d[:nest][:baz],  s.nest.baz
      assert_equal d[:nest][:quux], s.nest.quux
    end
  end

  describe "many" do
    before do
      Bar ||= Class.new OpenStruct
      Foo ||= Class.new OpenStruct 

      Class.new Mediator do
        accept Bar

        def parse! p
          p.many :foos
          p.many :merge_foos, merge: true
        end

        def construct name
          # name is either foo, replace_foo, replace_foos or foos..
          subject.foos         ||= []
          subject.merge_foos ||= []

          return subject.send(name) if subject.respond_to?(name)

          foo = Foo.new
          subject.send("#{name}s") << foo
          foo
        end
      end

      Class.new Mediator do
        accept Foo

        def parse! p
          p.key :baz
        end
      end
    end

    it "delegates to an array of nested mediator" do
      s  = Bar.new

      m = Mediator[s]
      d = { foos: [ { baz: "baz!" }, { baz: "blup?" } ] }

      m.parse d

      assert_equal d[:foos].map { |v| v[:baz] },  s.foos.map { |v| v.baz }
    end

    it "replaces all models by default" do
      s  = Bar.new foos: [ Foo.new(baz: "bar") ]

      assert_equal ["bar"], s.foos.map(&:baz)

      m = Mediator[s]
      d = { foos: [ { baz: "blup?" } ] }

      m.parse d

      assert_equal ["blup?"],  s.foos.map(&:baz)
    end

    it "does nothing with nil values by default" do
      s  = Bar.new foos: [ Foo.new(baz: "bar") ]

      assert_equal ["bar"], s.foos.map(&:baz)

      m = Mediator[s]
      d = { foos: nil }

      m.parse d

      assert_equal ["bar"],  s.foos.map(&:baz)
    end

    it "does something with []" do
      s  = Bar.new foos: [ Foo.new(baz: "bar") ]

      assert_equal ["bar"], s.foos.map(&:baz)

      m = Mediator[s]
      d = { foos: [] }

      m.parse d

      assert_equal [],  s.foos.map(&:baz)
    end

    it "adds new models if told to" do
      s  = Bar.new merge_foos: [ Foo.new(baz: "bar") ]

      m = Mediator[s]
      d = { merge_foos: [ { baz: "blup?" } ] }

      m.parse d

      assert_equal ["bar", "blup?"], s.merge_foos.map(&:baz)
    end
  end

  describe "union" do
    it "uses the same data as its parent" do
      First  = Class.new OpenStruct
      Second = Class.new OpenStruct

      Class.new Mediator do
        accept First

        def parse! p
          p.key   :first
          p.union :unioned
        end
      end

      Class.new Mediator do
        accept Second

        def parse! p
          p.key :second
        end
      end

      f = First.new
      s = Second.new

      f.unioned = s

      m = Mediator[f]

      m.parse first: "foo", second: "bar"

      assert_equal "foo", f.first
      assert_equal "bar", s.second
    end
  end
end
