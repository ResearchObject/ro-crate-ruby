module ROCrate
  ##
  # A class to represent a reference within an RO crate, to a remote file held on the internet somewhere.
  # It handles the actual reading/writing of bytes.
  class RemoteEntry
    attr_reader :uri

    ##
    # Create a new RemoteEntry.
    #
    # @param uri [URI] An absolute URI.
    def initialize(uri)
      @uri = uri
    end

    def write(dest)
      raise 'Cannot write to a remote entry!'
    end

    ##
    # Read from the source.
    #
    def read
      source.read
    end

    ##
    # @return [IO] An IO object for the remote resource.
    #
    def source
      open(uri)
    end

    ##
    # Does this RemoteEntry point to a directory on the disk?
    def directory?
      false
    end

    ##
    # Does this RemoteEntry point to a remote resource?
    def remote?
      true
    end

    def path
      uri.path
    end
  end
end
