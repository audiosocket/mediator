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

    def ids name, options = {}
      if name[-1] == "s" and !options[:no_strip_plurial]
        id_name = name[0..-2].intern
      else
        id_name = name
      end

      key "#{id_name}_ids", options.merge(from: name) 
    end

    def key name, options = nil, &block
      if name[-1] == "?"
        name = name[0..-2].intern
      end

      value = get name, options
      return if empty? value, options

      value = block ? block[value] : value

      mediator.set name, value unless empty? value, options
    end

    def many name, options = nil, &block
      data = get name, options
      subj = (options && options[:subject]) || mediator.get(name)

      data.map { |d| sub subj[data.index d], d, options, &block }.
        reject { |v| empty? v, options }
    end

    def one name, options = nil, &block
      data = get name, options
      subj = (options && options[:subject]) || mediator.get(name)

      sub subj, data, options, &block
    end

    def union name, options = nil, &block
      (options ||= {}).merge! value: self.data
      one name, options, &block
    end

    private

    def sub subj, data, options, &block
      return if empty? data, options or subj.nil?

      Mediator[subj, mediator].parse data
      block[subj] if block

      subj
    end
  end
end
