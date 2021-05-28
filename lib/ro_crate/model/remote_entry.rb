module ROCrate
  ##
  # A class to represent a reference within an RO-Crate, to a remote file held on the internet somewhere.
  # It handles the actual reading/writing of bytes.
  class RemoteEntry < Entry
    attr_reader :uri

    ##
    # Create a new RemoteEntry.
    #
    # @param uri [URI] An absolute URI.
    def initialize(uri)
      @uri = uri
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
  end
end
