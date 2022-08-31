module ROCrate
  ##
  # A generic "Entity" within an RO-Crate. It has an identifier and a set of properties, and will be referenced in the
  # RO-Crate Metadata's @graph.
  class Entity
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
    # Format the given ID with rules appropriate for this type if it is local/relative, leave as-is if absolute.
    #
    # @param id [String] The candidate ID to be formatted.
    # @return [String] The formatted ID.
    def self.format_id(id)
      begin
        uri = URI(id)
      rescue ArgumentError, URI::InvalidURIError
        uri = nil
      end

      if uri&.absolute?
        id
      else
        format_local_id(id)
      end
    end

    ##
    # Format the given local ID with rules appropriate for this type.
    # For example:
    #  * contextual entities MUST be absolute URIs, or begin with: #
    #  * files MUST NOT begin with ./
    #  * directories MUST NOT begin with ./ (except for the crate itself), and MUST end with /
    #
    # @param id [String] The candidate local ID to be formatted.
    # @return [String] The formatted local ID.
    def self.format_local_id(id)
      if id.start_with?('#')
        '#' + Addressable::URI.encode_component(id[1..-1], Addressable::URI::CharacterClasses::QUERY)
      else
        # Remove initial ./ if present
        Addressable::URI.encode_component(id.sub(/\A\.\//, ''), Addressable::URI::CharacterClasses::PATH)
      end
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
    # RO-Crate metadata file requires.
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
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this entity.
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
    # Lookup an Entity using the given ID (in this Entity's crate).
    #
    # @param id [String] The ID to query.
    # @return [Entity, nil]
    def dereference(id)
      crate.dereference(id)
    end
    alias_method :get, :dereference

    ##
    # Remove this entity from the RO-Crate.
    #
    # @param remove_orphaned [Boolean] Should linked contextual entities also be removed from the crate (if nothing else is linked to them)?
    #
    # @return [Entity, nil] This entity, or nil if nothing was deleted.
    def delete(remove_orphaned: true)
      crate.delete(self, remove_orphaned: remove_orphaned)
    end

    def id
      @properties['@id']
    end

    def id=(id)
      @canonical_id = nil
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

    ##
    # The "canonical", global ID of this entity relative to the canonical ID of the crate.
    #
    # In the case that the crate does not have an absolute URI as its ID, it will appear something like this:
    #   arcp://uuid,b3d6fa2b-4e49-43ba-bd89-464e948b7f0c/foo - where `foo` is the local ID of this entity.
    #
    # If the crate does have an absolute URI, it will appear relative to that e.g.:
    #   http://mycoolcrate.info/foo - where `foo` is the local ID of this entity.
    #
    # If the entity itself has an absolute URI, that will be used e.g.:
    #   http://website.com/foo.txt - where `http://website.com/foo.txt ` is the local ID of this entity.
    #
    # This is used, for example, to compare equality of two entities.
    #
    # @return [Addressable::URI]
    def canonical_id
      @canonical_id ||= crate.resolve_id(id)
    end

    ##
    # Is this entity local to the crate or an external reference?
    #
    # @return [Boolean]
    def external?
      crate.canonical_id.host != canonical_id.host
    end

    def raw_properties
      @properties
    end

    def [](key)
      @properties[key]
    end

    def []=(key, value)
      @properties[key] = value
    end

    def to_json
      @properties.to_json
    end

    ##
    # A safe way of checking if the Entity has the given type, regardless of whether the Entity has a single, or Array of types.
    # Does not check superclasses etc.
    # @param type [String] The type to check, e.g. "File".
    # @return [Boolean]
    def has_type?(type)
      @properties.has_type?(type)
    end

    ##
    # Gather a list of entities linked to this one through its properties.
    # @param deep [Boolean] If false, only consider direct links, otherwise consider transitive links.
    # @param linked [Hash{String => Entity}] Discovered entities, mapped by their ID, to avoid loops when recursing.
    # @return [Array<Entity>]
    def linked_entities(deep: false, linked: {})
      properties.each_key do |key|
        value = properties[key] # We're doing this to call the JSONLDHash#[] method which wraps
        value = [value] if value.is_a?(JSONLDHash)

        if value.respond_to?(:each)
          value.each do |v|
            if v.is_a?(JSONLDHash) && !linked.key?(v['@id'])
              entity = v.dereference
              next unless entity
              linked[entity.id] = entity
              if deep
                entity.linked_entities(deep: true, linked: linked).each do |e|
                  linked[e.id] = e
                end
              end
            end
          end
        end
      end

      linked.values.compact
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
