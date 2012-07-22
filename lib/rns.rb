require 'rns/version'

module Kernel
  def Rns(*imports, &block)
    klass = Class.new(Rns::Namespace, &block)
    klass.import(imports)
    klass.freeze.send(:new).freeze
  end
end

module Rns
  class ImportError < StandardError
  end

  class Namespace
    class << self
      private :new

      def import(imports)
        @_import_hash = Rns.array_to_key_value_tuples(imports).reduce({}) do |h, (obj, methods)|
          if !obj.frozen?
            raise ImportError, "#{obj} cannot be imported into a Namespace because it is not frozen"
          elsif !obj.class.frozen?
            raise ImportError, "#{obj} cannot be imported into a Namespace because its class is not frozen"
          end
          (methods || obj.public_methods(false)).each do |method|
            h[method.to_sym] = obj.method(method)
          end
          h
        end

        # file, line = caller[2].split(':', 2)
        # line = line.to_i
        @_import_hash.each do |method, _|
          source = <<-EOS
            def #{method}(*args, &block)
              self.class.instance_variable_get(:@_import_hash).fetch(:#{method}).call(*args, &block)
            end
          EOS
          module_eval(source) #, file, line - 2)
          private method
        end
      end
    end
  end

  class << self
    def array_to_key_value_tuples(array)
      array.reduce([]) do |tuples, elem|
        if elem.is_a? Hash
          tuples + Array(elem)
        else
          tuples << [elem, nil]
        end
      end
    end
  end
end