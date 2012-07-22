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
        @_import_hash = array_to_key_value_tuples(imports).reduce({}) do |h, (obj, methods)|
          if !obj.frozen?
            raise ImportError, "#{obj} cannot be imported into Namespace because it is not frozen"
          elsif !obj.class.frozen?
            raise ImportError, "#{obj} cannot be imported into Namespace because its class is not frozen"
          end
          (methods || obj.public_methods(false)).each do |method|
            h[method.to_sym] = obj.method(method)
          end
          h
        end

        # file, line = caller[2].split(':', 2)
        # line = line.to_i
        @_import_hash.each do |method, _|
          module_eval(delegate_to_hash_source(method, :@_import_hash)) #, file, line - 2)
          private method
        end
      end

    private
      def array_to_key_value_tuples(array)
        array.reduce([]) do |tuples, elem|
          if elem.is_a? Hash
            tuples + Array(elem)
          else
            tuples << [elem, nil]
          end
        end
      end

      def delegate_to_hash_source(method_name, hash_name)
        <<-EOS
          def #{method_name}(*args, &block)
            self.class.instance_variable_get(:#{hash_name}).fetch(:#{method_name}).call(*args, &block)
          end
        EOS
      end

    end
  end
end