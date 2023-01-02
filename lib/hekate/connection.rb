# frozen_string_literal: true

module Hekate
  class Connection
    extend Memoist

    attr_accessor :endpoint, :timeout

    def initialize(endpoint, timeout)
      @endpoint = endpoint
      @timeout = timeout
    end

    # rubocop:disable Metrics/MethodLength
    def can_connect?
      socket = Socket.new(Socket.const_get(address_family), Socket::SOCK_STREAM, 0)
      socket.setsockopt(Socket::IPPROTO_TCP, Socket::TCP_NODELAY, 1)
      # Initiate the socket connection in the background. If it doesn't fail
      # immediately it will raise an IO::WaitWritable (Errno::EINPROGRESS)
      # indicating the connection is in progress.
      socket.connect_nonblock(packed_address)
      true
    rescue IO::WaitWritable
      # IO.select will block until the socket is writable or the timeout
      # is exceeded - whichever comes first.
      if socket.wait_writable(timeout)
        begin
          # Verify there is now a good connection
          socket.connect_nonblock(packed_address)
        rescue Errno::EISCONN
          # Good news everybody, the socket is connected!
          return true
        rescue StandardError
          # An unexpected exception was raised - the connection is no good.
          socket.close
          return false
        end
        true
      else
        # IO.select returns nil when the socket is not ready before timeout
        # seconds have elapsed
        socket.close
        false
      end
    rescue StandardError
      false
    end
    # rubocop:enable Metrics/MethodLength

    private

    def address
      Socket.getaddrinfo(host, nil).first
    end

    def address_family
      address.first
    end

    def address_ip
      address[3]
    end

    def host
      endpoint.host
    end

    def packed_address
      Socket.pack_sockaddr_in(port, address_ip)
    end

    def port
      endpoint.port
    end
    memoize :address,
            :address_family,
            :address_ip,
            :host,
            :packed_address,
            :port
  end
end
