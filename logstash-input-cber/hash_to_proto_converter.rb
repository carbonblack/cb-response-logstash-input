module Minecart
  RuntimeError = Class.new(::RuntimeError)
  UnableToConstructProtoError = Class.new(Minecart::RuntimeError)
  ProtoNotFound = Class.new(Minecart::RuntimeError)
  
  module HashProtoBuilder
    extend self
    
    def hash_from_proto(proto)
      raise Minecart::ProtoNotFound unless proto.kind_of?(com.google.protobuf.Message)
      out = {}
      descriptor = proto.class.get_descriptor
      descriptor.fields.each do |field|
        if field.repeated?
          if field.type.name == "MESSAGE"
            out[field.name] = proto.send("#{field.name}_list").map{|m| hash_from_proto(m)}
          else
            out[field.name] = proto.send("#{field.name}_list").map{|m| m}
          end
        else
          name = normalize_proto_field_name(field.name)
          if proto.respond_to?("get_#{name}") && proto.send("has_#{name}")
            val = proto.send("get_#{name}")
            val = Hash.from_proto(val) if val.kind_of?(com.google.protobuf.Message)
            out[name] = val
          end
        end
      end
      out.respond_to?(:with_indifferent_access) ? out.with_indifferent_access : out
    end
    
    def hash_to_proto(builder_or_proto, hash)
      builder = builder_or_proto.respond_to?(:default_instance) ? builder_or_proto.default_instance : builder_or_proto
      builder = builder.respond_to?(:to_builder) ? builder.to_builder : builder
      hash.each do |k,v|
        key = normalize_proto_field_name(k.to_s.snake_case)
        case v
        when Hash
          raise "Unknown builder for #{key}" unless builder.respond_to?("get_#{key}_builder")
          builder.send("set_#{key}", hash_to_proto(builder.send("get_#{key}_builder"), v))
        when Array
          if builder.respond_to?("add_#{key}_builder")
            v.each do |val|
              idx = builder.send("get_#{key}_count")
              item_builder = builder.send("add_#{key}_builder", idx)
              hash_to_proto(item_builder, val)
            end
          else
            v.each do |val|
              builder.send("add_#{key}", val)
            end
          end
        when nil
          builder.send("clear_#{key}")
        else
          to_proto, transformer = get_proto_transformation(v.class)
          if to_proto
            builder.send("set_#{key}", hash_to_proto(to_proto.newBuilder, transformer.call(v)))
          else
            builder.send("set_#{key}", v)
          end
        end
      end
      builder.build
    
    rescue NoMethodError => e
      error = Minecart::UnableToConstructProtoError.new(e.message)
      error.set_backtrace e.backtrace
      raise error
    end
    
    def get_proto_transformation(klass)
      transformer = transformations[klass]
      while transformer.nil? && !klass.nil?
        klass = klass.superclass
        transformer = transformations[klass]
      end
      transformer ? transformer.dup : nil
    end
    
    def transformations
      @@transformations ||= {}
    end
    
    def set_transformations(transformations)
      @@transformations = transformations
    end
    
    private
    def normalize_proto_field_name(field_name)
      if field_name =~ /_\d+$/
        parts = field_name.split("_")
        suffix = parts.pop
        parts.last << suffix
        name = parts.join("_")
      else
        name = field_name
      end
    end
  end
end

# Tiny extension to help us out
class String
  # from: http://rubydoc.info/gems/extlib/0.9.15/String#camel_case-instance_method
  def camel_case
    return self if self !~ /_/ && self =~ /[A-Z]+.*/
    split('_').map{|e| e.capitalize}.join
  end

  def snake_case
    return downcase if match(/\A[A-Z]+\z/)
    gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
        gsub(/([a-z])([A-Z])/, '\1_\2').
        downcase
  end
end
