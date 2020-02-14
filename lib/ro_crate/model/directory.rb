module ROCrate
  ##
  # A data entity that represents a directory of potentially many files and subdirectories (or none).
  class Directory < DataEntity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def self.format_id(id)
      super + '/'
    end

    ##
    # Create a new Directory. PLEASE NOTE, the new directory will not be added to the crate. To do this, call
    # Crate#add_data_entity, or just use Crate#add_directory.
    #
    # @param crate [Crate] The RO crate that owns this directory.
    # @param source_directory [String, #read, nil] The source directory that will be included in the crate.
    # @param crate_path [String] The relative path within the RO crate where this directory will be written.
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this dectory.
    def initialize(crate, source_directory = nil, crate_path = nil, properties = {})
      raise 'Not a directory' if source_directory && !(::File.directory?(source_directory) rescue false)
      source_directory = Pathname.new(source_directory).expand_path if source_directory.is_a?(String) || source_directory.is_a?(::File)
      crate_path = source_directory.basename.to_s if crate_path.nil? && source_directory.respond_to?(:basename)
      super(crate, crate_path, properties)
      @directory_entries = {}
      if source_directory
        Dir.chdir(source_directory) { Dir.glob('**/*') }.each do |rel_path|
          source_path = Pathname.new(::File.join(source_directory, rel_path)).expand_path
          @directory_entries[rel_path] = Entry.new(source_path)
        end
      end
    end

    ##
    # A map of all the files/directories under this directory, where the key is the destination path within the crate
    # and the value is an Entry where the source data can be read.
    #
    # @return [Hash{String => Entry}>]
    def entries
      entries = {}

      @directory_entries.each do |rel_path, entry|
        entries[::File.join(filepath, rel_path)] = entry
      end

      entries
    end

    private

    def default_properties
      super.merge(
        '@id' => "#{SecureRandom.uuid}/",
        '@type' => 'Dataset'
      )
    end
  end
end
