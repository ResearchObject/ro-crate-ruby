require 'forwardable'

module ROCrate
  class Entity
    extend Forwardable
    def_delegators :@properties, :[], :[]=, :to_json
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
          @properties[prop] = value
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

    def initialize(crate, id = nil, properties = {})
      @crate = crate
      self.properties = default_properties.merge(properties)
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
      @properties = ROCrate::JSONLDHash.new(crate, props)
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

    private

    def default_properties
      {
        '@id' => "##{SecureRandom.uuid}",
        '@type' => 'Thing'
      }
    end
  end
end
