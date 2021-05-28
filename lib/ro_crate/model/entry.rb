module ROCrate
  ##
  # A class to represent a "physical" file or directory within an RO-Crate.
  # It handles the actual reading/writing of bytes.
  class Entry
    attr_reader :source

    ##
    # Create a new Entry.
    #
    # @param source [#read] An IO-like source that can be read.
    def initialize(source)
      @source = source
    end

    ##
    # Write the entry's source to the destination via a buffer.
    #
    # @param dest [#write] An IO-like destination to write to.
    def write_to(dest)
      input = source
      input = input.open('rb') if input.is_a?(Pathname)
      while (buff = input.read(4096))
        dest.write(buff)
      end
    end

    ##
    # Read from the source.
    #
    def read
      source.read
    end

    ##
    # Does this Entry point to a directory on the disk?
    def directory?
      ::File.directory?(source) rescue false
    end

    ##
    # Does this Entry point to a remote resource?
    def remote?
      false
    end

    def path
      if source.is_a?(Pathname)
        source.to_s
      elsif source.respond_to?(:path)
        source.path
      else
        nil
      end
    end
  end
end
