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
    # @param source_directory [String, Pathname, ::File, nil] The source directory that will be included in the crate.
    # @param crate_path [String] The relative path within the RO crate where this directory will be written.
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this directory.
    def initialize(crate, source_directory = nil, crate_path = nil, properties = {})
      @directory_entries = {}

      if source_directory
        source_directory = Pathname.new(::File.expand_path(source_directory))
        populate_entries(source_directory)
        crate_path = source_directory.basename.to_s if crate_path.nil?
      end

      super(crate, crate_path, properties)
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

    ##
    # Populate this directory with files/directories from a given source directory on disk.
    #
    # @param source_directory [Pathname] The source directory to populate from.
    #
    # @return [Hash{String => Entry}>] The files/directories that were populated.
    #   The key is the relative path of the file/directory, and the value is an Entry object where data can be read etc.
    def populate_entries(source_directory)
      raise 'Not a directory' unless ::File.directory?(source_directory)
      @directory_entries = {}
      Dir.chdir(source_directory) { Dir.glob('**/*') }.each do |rel_path|
        source_path = Pathname.new(::File.join(source_directory, rel_path)).expand_path
        @directory_entries[rel_path] = Entry.new(source_path)
      end

      @directory_entries
    end

    def default_properties
      super.merge(
        '@id' => "#{SecureRandom.uuid}/",
        '@type' => 'Dataset'
      )
    end
  end
end
