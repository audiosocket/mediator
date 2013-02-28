require "mediator/processor"

class Mediator
  class Renderer < Processor
    attr_reader :data
    attr_reader :mediator

    def initialize mediator, data = nil
      @data     = data || {}
      @mediator = mediator
    end

    def get name, options = {}
      options = {construct: false}.merge options
      selector = options[:from] || name
      options[:value] || mediator.get(selector, options)
    end

    def has? name, options = {}
      selector = options[:from] || name
      options.has_key?(:value)  || mediator.subject_has?(selector)
    end

    def id name, options = {}, &block
      key name, options.merge(from: "#{name}_id"), &block
    end

    def ids name, options = {}, &block
      unless options[:from]
        if name[-1] == "s"
          options = options.merge(from: "#{name[0..-2]}_ids")
        else
          options = options.merge(from: "#{name}_ids")
        end
      end

      key name, options, &block
    end

    def key name, options = {}, &block
      if name[-1] == "?"
        options[:from] = name
        name = name[0..-2].intern
      end

      value = get name, options
      return if empty? value, options

      value = block ? block[value] : value

      data[name] = value unless empty? value, options
    end

    def many name, options = {}, &block
      value = get name, options
      data[name] = value.map { |v| sub v, options, &block }.
        reject { |v| empty? v, options }
    end

    def one name, options = {}, &block
      value = get name, options
      return if empty? value, options
 
      value = sub value, options, &block 
      return if empty? value, options

      options[:merge] ? data.merge!(value) : data[name] = value
    end

    def union name, options = {}, &block
      options.merge! merge: true
      one name, options, &block
    end

    private

    def sub value, options, &block
      rendered = Mediator[value, context: mediator].render
      block ? block[rendered] : rendered
    end

  end
end
