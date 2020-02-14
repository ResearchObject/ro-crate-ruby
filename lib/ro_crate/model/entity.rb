require 'forwardable'

module ROCrate
  class Entity
    extend Forwardable
    def_delegators :@properties, :[], :[]=, :to_json, :has_type?
    attr_reader :crate
    attr_reader :properties

    ##
    # Define Ruby-style getters/setters for the given list of properties.
    # The getters/setters will have underscored names, and will automatically reference/dereference entities within the
    # crate using their `@id`.
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

    ##
    # Format the given ID with rules appropriate for this type.
    # For example:
    #  * contextual entities MUST be absolute URIs, or begin with: #
    #  * files MUST NOT begin with ./
    #  * directories MUST NOT begin with ./ (except for the crate itself), and MUST end with /
    def self.format_id(id)
      Addressable::URI.escape(id.sub(/\A\.\//, '')) # Remove initial ./ if present
    end

    ##
    # Automatically replace references to entities (e.g. `{ '@id' : '#something' }`) with the Entity object itself.
    #
    # @param value [Hash, Array<Hash>, Object] A value that may be reference or array of references.
    # @return [Entity, Array<Entity>, Object] Return an Entity, Array of Entities, or just the object itself if
    #   it wasn't a reference after all.
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

    ##
    # Automatically replace an Entity or Array of Entities with a reference or Array of references. Also associates
    # the Entity/Entities with the current crate. This is useful for maintaining the flat @graph of entities that the
    # RO crate metadata file requires.
    #
    # @param value [Entity, Array<Entity>, Object] A value that may be reference or array of references.
    # @return [Hash, Array<Hash>, Object] Return a reference, Array of references, or just the object itself if
    #   it wasn't an Entity after all.
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

    ##
    # Create a new Entity.
    #
    # @param crate [Crate] The crate that owns this Entity.
    # @param id [String, nil] An ID to identify this Entity, or blank to auto-generate an appropriate one,
    #   (or determine via the properties param)
    # @param properties [Hash] A hash of JSON-LD properties to associate with this entity.
    def initialize(crate, id = nil, properties = {})
      @crate = crate
      @properties = ROCrate::JSONLDHash.new(crate, default_properties.merge(properties))
      self.id = id if id
    end

    ##
    # Return a JSON-LD style reference: { '@id' : '#an-entity' } for this Entity.
    #
    # @return [Hash]
    def reference
      ROCrate::JSONLDHash.new(crate, '@id' => id)
    end

    ##
    # Resolve a style reference: { '@id' : '#an-entity' } to another Entity within the same crate, or nil if it wasn't found.
    #
    # @return [Entity, nil]
    def dereference(id)
      crate.entities.detect { |e| e.canonical_id == crate.resolve_id(id) } if id
    end

    def id
      @properties['@id']
    end

    def id=(id)
      @properties['@id'] = self.class.format_id(id)
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

    ##
    # Turn a generic Entity into a specialization based on it's @type
    # @return [Person, Organization, ContactPoint, Entity]
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
