require "mediator/processor"

class Mediator
  class Renderer < Processor
    attr_reader :data
    attr_reader :mediator

    def initialize mediator, data = nil
      @data     = data || {}
      @mediator = mediator
    end

    def get name, options = nil
      selector = (options && options[:from]) || name
      (options && options[:value]) || mediator.get(selector)
    end

    def has? name, options = nil
      selector = (options && options[:from]) || name
      (options && options.has_key?(:value)) || mediator.subject.respond_to?(selector) || mediator.subject.respond_to?(selector.to_s)
    end

    def id name, options = {}
      key name, options.merge(from: "#{name}_id")
    end

    def ids name, options = {}
      unless options[:from]
        if name[-1] == "s"
          options = options.merge(from: "#{name[0..-2]}_ids")
        else
          options = options.merge(from: "#{name}_ids")
        end
      end

      key name, options
    end

    def key name, options = nil, &block
      if name[-1] == "?"
        (options ||= {})[:from] = name
        name = name[0..-2].intern
      end

      return unless has? name, options

      value = get name, options
      return if empty? value, options

      value = block ? block[value] : value

      data[name] = value unless empty? value, options
    end

    def many name, options = nil, &block
      value = get name, options
      data[name] = value.map { |v| sub v, options, &block }.
        reject { |v| empty? v, options }
    end

    def one name, options = nil, &block
      value = get name, options
      return if empty? value, options
 
      value = sub value, options, &block 
      return if empty? value, options

      options && options[:merge] ? data.merge!(value) : data[name] = value
    end

    def union name, options = nil, &block
      (options ||= {}).merge! merge: true
      one name, options, &block
    end

    private

    def sub value, options, &block
      rendered = Mediator[value, mediator].render
      block ? block[rendered] : rendered
    end

  end
end
