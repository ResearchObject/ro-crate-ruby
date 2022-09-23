module ROCrate
  ##
  # A class to represent a "Data Entity" within an RO-Crate.
  # Data Entities are the actual physical files and directories within the Crate.
  class DataEntity < Entity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs author])

    ##
    # Return an appropriate specialization of DataEntity for the given properties.
    # @param props [Hash] Set of properties to try and infer the type from.
    # @return [Class]
    def self.specialize(props)
      type = props['@type']
      type = [type] unless type.is_a?(Array)
      if type.include?('Dataset')
        ROCrate::Directory
      elsif type.include?('File')
        ROCrate::File
      else
        self
      end
    end

    ##
    # Create a new ROCrate::DataEntity. This entity represents something that is neither a file or directory, but
    # still constitutes part of the crate.
    # PLEASE NOTE, the new data entity will not be added to the crate. To do this, call Crate#add_data_entity.
    #
    # @param crate [Crate] The RO-Crate that owns this directory.
    # @param source [String, Pathname, ::File, URI, nil, #read] The source on the disk (or on the internet if a URI)
    # where the content of this DataEntity can be found.
    # @param crate_path [String, nil] The relative path within the RO-Crate where this data entity should be written.
    # Also used as the ID of the DataEntity. Will be taken from `properties` or generated if `crate_path` is nil.
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this DataEntity.
    def initialize(crate, source = nil, crate_path = nil, properties = {})
      if crate_path.is_a?(Hash) && properties.empty?
        properties = crate_path
        crate_path = nil
      end

      @source = normalize_source(source)

      if crate_path.nil?
        crate_path = @source.basename.to_s if @source.respond_to?(:basename)
        crate_path = @source.to_s if @source.is_a?(URI) && @source.absolute?
      end

      super(crate, crate_path, properties)
    end

    ##
    # The payload of all the files/directories associated with this DataEntity, mapped by their relative file path.
    #
    # @return [Hash{String => Entry}>] The key is the location within the crate, and the value is an Entry.
    def payload
      {}
    end
    alias_method :entries, :payload

    ##
    # A disk-safe filepath based on the ID of this DataEntity.
    #
    # @return [String] The relative file path of this DataEntity within the Crate.
    def filepath
      Addressable::URI.unescape(id.sub(/\A\//, '')).to_s # Remove initial / and decode %20 etc.
    end

    private

    ##
    # Do some normalization of the given source. Coverts `::File` and `String` (if relative path) to `Pathname`
    # and ensures they are expanded.
    #
    # @param source [String, Pathname, ::File, URI, nil, #read] The source on the disk (or on the internet if a URI).
    # @return [Pathname, URI, nil, #read] An absolute Pathname or URI for the source.
    def normalize_source(source)
      if source.is_a?(String)
        uri = URI(source) rescue nil
        if uri&.absolute?
          source = uri
        else
          source = Pathname.new(source)
        end
      elsif source.is_a?(::File)
        source = Pathname.new(source)
      end

      source.is_a?(Pathname) ? source.expand_path : source
    end
  end
end
