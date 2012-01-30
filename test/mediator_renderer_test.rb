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

  describe "id" do
    it "grabs an id" do
      c = Class.new Mediator do
        def render! r
          r.id :foo
        end
      end

      x = OpenStruct.new foo_id: 5
      m = c.new x
      r = { foo: 5 }

      assert_equal r, m.render
    end
  end

  describe "ids" do
    it "grabs an array of ids" do
      c = Class.new Mediator do
        def render! r
          r.ids :foo
        end
      end

      x = OpenStruct.new foo_ids: [5, 6, 7]
      m = c.new x
      r = { foo: [5, 6, 7] }

      assert_equal r, m.render
    end
  end

  describe "many" do
    it "grabs a collection from the subject" do
      c = Class.new Mediator do
        def render! r
          r.many :foo
        end
      end

      d = Class.new Mediator do
        accept OpenStruct

        def render! r
          r.key :bar
        end
      end

      x = OpenStruct.new bar: "gni"
      y = OpenStruct.new bar: "gno"
      s = OpenStruct.new foo: [x, y]
      m = c.new s
      d = m.render

      r = { foo: [ { bar: "gni" }, { bar: "gno" } ] }
      assert_equal r, d
    end

    it "can alter values" do
      c = Class.new Mediator do
        def render! r
          r.many(:foo) { |v| { bar: v[:bar].upcase } }
        end
      end

      d = Class.new Mediator do
        accept OpenStruct

        def render! r
          r.key :bar
        end
      end

      x = OpenStruct.new bar: "gni"
      y = OpenStruct.new bar: "gno"
      s = OpenStruct.new foo: [x, y]
      m = c.new s
      d = m.render

      r = { foo: [ { bar: "GNI" }, { bar: "GNO" } ] }
      assert_equal r, d
    end

    it "removes empty values" do
      c = Class.new Mediator do
        def render! r
          r.many :foo
        end
      end

      d = Class.new Mediator do
        accept OpenStruct

        def render! r
          r.key :bar if subject.bar == "gni"
        end
      end

      x = OpenStruct.new bar: "gni"
      y = OpenStruct.new bar: "gno"
      s = OpenStruct.new foo: [x, y]
      m = c.new s
      d = m.render

      r = { foo: [ { bar: "gni" } ] }
      assert_equal r, d
    end
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

    it "ignores nil or empty values returned by blocks" do
      c = Class.new Mediator do
        def render! r
          r.key(:foo) { |p| nil }
        end
      end

      s = OpenStruct.new foo: "bar"
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

  describe "one" do
    it "allows mediation of an associated object" do
      c = Class.new Mediator do
        def render! r
          r.one :foo
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
