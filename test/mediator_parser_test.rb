require "mediator"
require "mediator/parser"
require "minitest/autorun"
require "ostruct"

describe Mediator::Parser do
  before do
    Mediator.map.clear

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

    it "does not remove plurial if told to" do
      p = Mediator::Parser.new @mediator, foos: [5, 6, 7]

      p.ids :foos, no_strip_plurial: true
      assert_equal [5, 6, 7], @subject.foos_ids
    end
  end

  describe "key" do
    before do
      @parser = Mediator::Parser.new @mediator,
        emptystring: "", emptyarray: [], isnil: nil,
        somevalue: :gni, predicate: true
    end

    it "parses some values" do
      @parser.key :somevalue

      assert_equal :gni, @subject.somevalue
    end

    it "sets unconditionally with empty: true" do
      @subject.foo = :foo

      @parser.key :foo, empty: true
      assert_nil @subject.foo
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
      Many   = Class.new OpenStruct
      Nested = Class.new OpenStruct 

      Class.new Mediator do
        accept Many

        def parse! p
          p.many :nest
        end
      end

      Class.new Mediator do
        accept Nested

        def parse! p
          p.key :baz
        end
      end
    end

    it "delegates to an array of nested mediator" do
      s      = Many.new
      s.nest = [ Nested.new, Nested.new ]

      m = Mediator[s]
      d = { nest: [ { baz: "baz!" }, { baz: "blup?" } ] }

      m.parse d

      assert_equal d[:nest].map { |v| v[:baz] },  s.nest.map { |v| v.baz }
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
