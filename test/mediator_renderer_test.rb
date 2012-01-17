require "mediator"
require "mediator/renderer"
require "minitest/autorun"
require "ostruct"

describe Mediator::Renderer do
  before do
    Mediator.map.clear
  end

  it "has data" do
    assert_equal Hash.new, Mediator::Renderer.new(nil).data
  end

  describe "key" do
    it "grabs the value from the subject" do
      c = Class.new Mediator do
        def render! r
          r.key :foo
        end
      end

      s = OpenStruct.new foo: "bar"
      m = c.new s
      d = m.render

      assert_equal "bar", d[:foo]
    end

    it "removes trailing ? from predicates" do
      c = Class.new Mediator do
        def render! r
          r.key :foo?
        end
      end

      s = OpenStruct.new :foo? => true
      m = c.new s
      d = m.render

      assert d[:foo]
    end

    it "ignores nil or empty values" do
      c = Class.new Mediator do
        def render! r
          r.key :foo
        end
      end

      s = OpenStruct.new
      m = c.new s
      d = m.render

      assert_equal Hash.new, d
    end

    it "optionally allows empty values" do
      c = Class.new Mediator do
        def render! r
          r.key :foo, empty: true
        end
      end

      s = OpenStruct.new
      m = c.new s
      d = m.render
      e = { foo: nil }

      assert_equal e, d
    end

    it "optionally maps names" do
      c = Class.new Mediator do
        def render! r
          r.key :foo, from: :bar
        end
      end

      s = OpenStruct.new bar: "baz"
      m = c.new s
      d = m.render

      assert_equal "baz", d[:foo]
    end

    it "can alter values" do
      c = Class.new Mediator do
        def render! r
          r.key(:foo) { |v| v.upcase }
        end
      end

      s = OpenStruct.new foo: "bar"
      m = c.new s
      r = Mediator::Renderer.new s
      d = m.render

      assert_equal "BAR", d[:foo]
    end

    it "can explicitly define a value" do
      c = Class.new Mediator do
        def render! r
          r.key :foo, value: "bar"
        end
      end

      s = OpenStruct.new
      m = c.new s
      d = m.render

      assert_equal "bar", d[:foo]      
    end
  end

  describe "obj" do
    it "allows mediation of an associated object" do
      c = Class.new Mediator do
        def render! r
          r.obj :foo
        end
      end

      d = Class.new Mediator do
        accept OpenStruct

        def render! r
          r.key :bar
        end
      end

      x = OpenStruct.new bar: "baz"
      s = OpenStruct.new foo: x

      m = c.new s
      d = m.render
      e = { foo: { bar: "baz" } }

      assert_equal e, d
    end
  end
end
