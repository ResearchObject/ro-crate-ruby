module ROCrate
  ##
  # A data entity that represents a directory of potentially many files and subdirectories (or none).
  class Directory < DataEntity
    properties(%w[name contentSize dateModified encodingFormat identifier sameAs])

    def self.format_local_id(id)
      super + '/'
    end

    ##
    # Create a new Directory. PLEASE NOTE, the new directory will not be added to the crate. To do this, call
    # Crate#add_data_entity, or just use Crate#add_directory.
    #
    # @param crate [Crate] The RO-Crate that owns this directory.
    # @param source_directory [String, Pathname, ::File, nil] The source directory that will be included in the crate.
    # @param crate_path [String] The relative path within the RO-Crate where this directory will be written.
    # @param properties [Hash{String => Object}] A hash of JSON-LD properties to associate with this directory.
    def initialize(crate, source_directory = nil, crate_path = nil, properties = {})
      @directory_entries = {}

      if source_directory
        source_directory = Pathname.new(::File.expand_path(source_directory))
        @entry = Entry.new(source_directory)
        populate_entries(source_directory)
        crate_path = source_directory.basename.to_s if crate_path.nil?
      end

      super(crate, crate_path, properties)
    end

    ##
    # The "payload" of this directory - a map of all the files/directories, where the key is the destination path
    # within the crate and the value is an Entry where the source data can be read.
    #
    # @return [Hash{String => Entry}>]
    def entries
      entries = {}
      entries[filepath.chomp('/')] = @entry if @entry

      @directory_entries.each do |rel_path, entry|
        entries[full_entry_path(rel_path)] = entry
      end

      entries
    end

    private

    ##
    # Populate this directory with files/directories from a given source directory on disk.
    #
    # @param source_directory [Pathname] The source directory to populate from.
    # @param include_hidden [Boolean] Whether to include hidden files, i.e. those prefixed by a `.` (period).
    #
    # @return [Hash{String => Entry}>] The files/directories that were populated.
    #   The key is the relative path of the file/directory, and the value is an Entry object where data can be read etc.
    def populate_entries(source_directory, include_hidden: false)
      raise 'Not a directory' unless ::File.directory?(source_directory)
      @directory_entries = {}
      list_all_files(source_directory, include_hidden: include_hidden).each do |rel_path|
        source_path = Pathname.new(::File.join(source_directory, rel_path)).expand_path
        @directory_entries[rel_path] = Entry.new(source_path)
      end

      @directory_entries
    end

    def full_entry_path(relative_path)
      ::File.join(filepath, relative_path)
    end

    def list_all_files(source_directory, include_hidden: false)
      args = ['**/*']
      args << ::File::FNM_DOTMATCH if include_hidden
      Dir.chdir(source_directory) { Dir.glob(*args) }.reject do |path|
        path == '.' || path == '..' || path.end_with?('/.')
      end
    end

    def default_properties
      super.merge(
        '@id' => "#{SecureRandom.uuid}/",
        '@type' => 'Dataset'
      )
    end
  end
end
