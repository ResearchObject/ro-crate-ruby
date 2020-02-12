require 'forwardable'

module ROCrate
  class Entity
    extend Forwardable
    def_delegators :@properties, :[], :[]=, :to_json, :has_type?
    attr_reader :crate
    attr_reader :properties

    # Define Ruby-style getters/setters for the given list of properties.
    def self.properties(props)
      props.each do |prop|
        # Convert camelCase to under_score
        underscored = prop.gsub(/([[:upper:]]*)([[:upper:]])([[:lower:]])/) do
          m = Regexp.last_match
          "#{m[1].downcase}_#{m[2].downcase}#{m[3]}"
        end

        define_method(underscored) do
          auto_dereference(@properties[prop])
        end

        define_method("#{underscored}=") do |value|
          @properties[prop] = auto_reference(value)
        end
      end
    end

    def auto_dereference(value)
      if value.is_a?(Array)
        return value.map { |v| auto_dereference(v) }
      end

      if value.is_a?(Hash) && value['@id']
        obj = dereference(value['@id'])
        return obj if obj
      end

      value
    end

    def auto_reference(value)
      if value.is_a?(Array)
        return value.map { |v| auto_reference(v) }
      end

      if value.is_a?(Entity)
        # If it's from another crate, need to add it to this one.
        crate.add_contextual_entity(value)

        return value.reference
      end

      value
    end

    def initialize(crate, id = nil, properties = {})
      @crate = crate
      @properties = ROCrate::JSONLDHash.new(crate, default_properties.merge(properties))
      self.id = id if id
    end

    def reference
      ROCrate::JSONLDHash.new(crate, '@id' => id)
    end

    def dereference(id)
      crate.entities.detect { |e| e.canonical_id == crate.resolve_id(id) } if id
    end

    def id
      @properties['@id']
    end

    def id=(id)
      @properties['@id'] = Addressable::URI.escape(id)
    end

    def type
      @properties['@type']
    end

    def type=(type)
      @properties['@type'] = type
    end

    def properties=(props)
      @properties.replace(props)
    end

    def inspect
      prop_string = properties.inspect
      prop_string = prop_string[0...509] + '...' if prop_string.length > 509
      "<##{self.class.name} #{canonical_id} @properties=#{prop_string}>"
    end

    def hash
      canonical_id.hash
    end

    def ==(other)
      return super unless other.is_a?(Entity)
      canonical_id == other.canonical_id
    end

    def eql?(other)
      return super unless other.is_a?(Entity)
      canonical_id == other.canonical_id
    end

    def canonical_id
      crate.resolve_id(id)
    end

    def raw_properties
      @properties
    end

    # Turn a generic Entity into a specialization based on it's @type
    def specialize
      if has_type?('Person')
        ROCrate::Person.new(crate, id, properties)
      elsif has_type?('Organization')
        ROCrate::Organization.new(crate, id, properties)
      elsif has_type?('ContactPoint')
        ROCrate::ContactPoint.new(crate, id, properties)
      else
        self
      end
    end

    private

    def default_properties
      {
        '@id' => "##{SecureRandom.uuid}",
        '@type' => 'Thing'
      }
    end
  end
end
