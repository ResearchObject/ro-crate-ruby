module ROCrate
  class Entity
    def self.properties(props)
      props.each do |prop|
        underscored = prop.gsub(/([[:upper:]]*)([[:upper:]])([[:lower:]])/) { "#{$1.downcase}_#{$2.downcase}#{$3}" }

        define_method(underscored) do
          @properties[prop]
        end

        define_method("#{underscored}=") do |value|
          @properties[prop] = value
        end
      end
    end

    def initialize(crate, id = nil)
      @crate = crate
      self.properties = default_properties
      self.id = id if id
    end

    def reference
      ROCrate::JSONLDHash.new(@crate, '@id' => id)
    end

    def dereference(id)
      @crate.entities.detect { |entity| entity.absolute_id == @crate.absolute(id) } if id
    end

    def id
      @properties['@id']
    end

    def id=(id)
      @properties['@id'] = id
    end

    def type
      @properties['@type']
    end

    def type=(type)
      @properties['@type'] = type
    end

    def to_json
      @properties.to_json
    end

    def properties
      @properties
    end

    def properties= props
      @properties = ROCrate::JSONLDHash.new(@crate, props)
    end

    def inspect
      prop_string = self.properties.inspect
      prop_string = prop_string[0...512] + '...' if prop_string.length > 512
      "<##{self.class.name}:#{self.absolute_id} @properties=#{prop_string}>"
    end

    def hash
      self.absolute_id.hash
    end

    def ==(other)
      self.absolute_id == other.absolute_id
    end

    def eql?(other)
      self.absolute_id == other.absolute_id
    end

    def absolute_id
      @crate.absolute(id)
    end

    private

    def default_properties
      {
          '@id' => "./#{SecureRandom.uuid}",
          '@type' => 'Thing'
      }
    end
  end
end
