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

    def has? name, options = nil
      selector = (options && options[:from]) || name
      (options && options.has_key?(:value))  || mediator.data_has?(data,selector)
    end

    def id name, options = {}
      key "#{name}_id", options.merge(from: name)
    end

    def ids name, options = {}
      if name[-1] == "s" and !options[:from]
        id_name = "#{name[0..-2]}_ids"
      else
        id_name = "#{name}_ids"
      end

      options[:from] ||= name

      key id_name, options
    end

    def key name, options = nil, &block
      if name[-1] == "?"
        name = name[0..-2].intern
      end

      return unless has? name, options

      value = get name, options
      return if empty? value, options

      value = block ? block[value] : value

      mediator.set name, value unless empty? value, options
    end

    def many name, options = nil, &block
      mediator.set name, [] if options && options[:replace]

      data = get(name, options) || []
      subj = (options && options[:subject]) || mediator.get(name)

      data.each do |d|
        unless d[:id] and s = subj.detect { |s| s.id == d[:id] }
          name = name[0..-2] if name[-1] == "s"
          s = mediator.construct name
        end
        
        sub s, d, options, &block
      end
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

      Mediator[subj, context: mediator].parse data
      block[subj] if block

      subj
    end
  end
end
