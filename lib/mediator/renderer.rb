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

    def id name, options = {}
      key name, options.merge(from: "#{name}_id")
    end

    def key name, options = nil, &block
      if name[-1] == "?"
        (options ||= {})[:from] = name
        name = name[0..-2].intern
      end

      value = get name, options
      return if empty? value, options

      value = block ? block[value] : value

      data[name] = value unless empty? value, options
    end

    def obj name, options = nil, &block
      value = get name, options
      return if empty? value, options

      if value
        rendered = Mediator[value, mediator].render
        munged   = block ? block[rendered] : rendered
        merge    = options && options[:merge]

        merge ? data.merge!(munged) : data[name] = munged
        munged
      end
    end

    def union name, options = nil, &block
      (options ||= {}).merge! merge: true
      obj name, options, &block
    end
  end
end
