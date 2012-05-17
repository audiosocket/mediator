class Mediator
  class Processor
    def empty? value, options = nil
      !(options && options[:empty]) &&
        (value.nil? || (value.respond_to?(:empty?) && value.empty?))
    end
  end
end
