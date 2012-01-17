require "mediator/processor"

class Mediator
  class Parser < Processor
    attr_reader :data
    attr_reader :mediator

    def initialize mediator, data = {}
      @data     = data
      @mediator = mediator
    end

    def get name, options = nil
      selector = (options && options[:from]) || name
      (options && options[:value]) || data[selector] || data[selector.to_s]
    end

    def has? name
      !!get(name)
    end

    def id name, options = {}
      key "#{name}_id", options.merge(from: name)
    end

    def key name, options = nil, &block
      if name[-1] == "?"
        name = name[0..-2].intern
      end

      value = get name, options

      return if empty? value, options
      mediator.set name, block ? block[value] : value
    end

    def obj name, options = nil, &block
      data = get name, options
      subj = (options && options[:subject]) || mediator.get(name)

      return if empty? data, options or subj.nil?

      Mediator[subj, mediator].parse data
      block[subj] if block

      subj
    end

    def union name, options = nil, &block
      (options ||= {}).merge! value: self.data
      obj name, options, &block
    end
  end
end
