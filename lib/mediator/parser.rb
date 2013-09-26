require "mediator/processor"

class Mediator
  class Parser < Processor
    attr_reader :data
    attr_reader :mediator

    def initialize mediator, data = {}
      @data     = data
      @mediator = mediator
    end

    def get name, options = {}
      selector = options[:from] || name
      options[:value] || data[selector] || data[selector.to_s]
    end

    def has? name, options = {}
      selector = options[:from] || name
      options.has_key?(:value)  || mediator.data_has?(data,selector)
    end

    def id name, options = {}
      key "#{name}_id", options.merge(from: name)
    end

    def ids name, options = {}
      if name[-1] == "s" and !options[:from]
        id_name = "#{name.to_s.singularize}_ids"
      else
        id_name = "#{name}_ids"
      end

      options[:from] ||= name

      key id_name, options
    end

    def key name, options = {}, &block
      if name[-1] == "?"
        name = name[0..-2].intern
      end

      return unless has? name, options

      value = get name, options
      return if empty? value, options

      value = block ? block[value] : value

      mediator.set name, value unless empty? value, options
    end

    def many name, options = {}, &block
      options = {construct: true}.merge options

      data = get(name, options)
      return if data.nil? and !options[:empty] # Can't use main empty? call here as [] does not count as empty..

      mediator.set name, [] unless options[:merge]

      subj = (options && options[:subject]) || mediator.get(name, options)

      (data || []).each do |d|
        name = name[0..-2] if name[-1] == "s"
        s = mediator.construct name
        sub s, d, options, &block
      end
    end

    def one name, options = {}, &block
      options = {construct: true}.merge options

      data = get name, options
      subj = options[:subject] || mediator.get(name, options)

      sub subj, data, options, &block
    end

    def union name, options = {}, &block
      options = {value: self.data}.merge options
      one name, options, &block
    end

    def nested name, options = {}, &block
      return if !block or empty? data[name], options
      p = mediator.parser data[name]
      block[p]
    end

    def hash name, options = {}, &block
      hash = mediator.get name, options

      exclude = options[:exclude] || []

      hash = (hash || {}).dup

      if exclude.respond_to? :call
        hash = hash.merge(data.reject(&exclude))
      else
        data.reject { |k, v| exclude.include? k.to_sym }.each do |k, v|
          hash[k.to_sym] = v
        end
      end

      mediator.set name, hash
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
