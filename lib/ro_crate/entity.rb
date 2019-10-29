require 'securerandom'

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
      @properties = default_properties
      self.id = id if id
    end

    def dereference(id)
      ids = [id]
      if id == './'
        ids << '.'
      elsif id.start_with?('./')
        ids << id.sub(/\A.\//, '')
      end
      @crate.entities.detect { |entry| ids.any? { |id| entry.id == id } }
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

    def reference
      { '@id' => id }
    end

    def properties
      @properties
    end

    def properties= props
      @properties = props
    end

    def inspect
      "<##{self.class.name}: id='#{self.id}' @properties='#{self.properties.inspect[0...128]}'>"
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
