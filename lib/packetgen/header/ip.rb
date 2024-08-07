# frozen_string_literal: true

# This file is part of PacketGen
# See https://github.com/lemontree55/packetgen for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# Copyright (C) 2024 LemonTree55 <lenontree@proton.me>
# This program is published under MIT license.

require 'socket'

module PacketGen
  module Header
    # IP protocol ({https://tools.ietf.org/html/rfc791 RFC 791})
    #    0                   1                   2                   3
    #    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
    #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    #   |Version|  IHL  |Type of Service|          Total Length         |
    #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    #   |         Identification        |Flags|      Fragment Offset    |
    #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    #   |  Time to Live |    Protocol   |         Header Checksum       |
    #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    #   |                       Source Address                          |
    #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    #   |                    Destination Address                        |
    #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    #   |                    Options                    |    Padding    |
    #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
    # A IP header consists of:
    # * a first byte ({#u8} of {Types::Int8} type) composed of:
    #   * a 4-bit {#version} field,
    #   * a 4-bit IP header length ({#ihl}) field,
    # * a Type of Service field ({#tos}, {Types::Int8} type),
    # * a total length ({#length}, {Types::Int16} type),
    # * a ID ({#id}, +Int16+ type),
    # * a {#frag} worg (+Int16+) composed of:
    #   * 3 1-bit flags ({#flag_rsv}, {#flag_df} and {#flag_mf}),
    #   * a 13-bit {#fragment_offset} field,
    # * a Time-to-Live ({#ttl}) field (+Int8+),
    # * a {#protocol} field (+Int8+),
    # * a {#checksum} field (+Int16+),
    # * a source IP address ({#src}, {Addr} type),
    # * a destination IP address ({#dst}, +Addr+ type),
    # * an optional {#options} field ({Options} type),
    # * and a {#body} ({Types::String} type).
    #
    # == Create a IP header
    #  # standalone
    #  ip = PacketGen::Header::IP.new
    #  # in a packet
    #  pkt = PacketGen.gen('IP')
    #  # access to IP header
    #  pkt.ip   # => PacketGen::Header::IP
    #
    # == IP attributes
    #  ip.u8 = 0x45
    #  # the same as
    #  ip.version = 4
    #  ip.ihl = 5
    #
    #  ip.length = 0x43
    #  ip.id = 0x1234
    #
    #  ip.frag = 0x2031
    #  # the same as:
    #  ip.flag_mf = true
    #  ip.fragment_offset = 0x31
    #
    #  ip.flag_rsv?  # => Boolean
    #  ip.flag_df?   # => Boolean
    #  ip.flag_mf?   # => Boolean
    #
    #  ip.ttl = 0x40
    #  ip.protocol = 6
    #  ip.checksum = 0xffff
    #  ip.src = '127.0.0.1'
    #  ip.src                # => "127.0.0.1"
    #  ip[:src]              # => PacketGen::Header::IP::Addr
    #  ip.dst = '127.0.0.2'
    #  ip.body.read 'this is a body'
    #
    # == Add IP options
    # IP has an {#options} attribute used to store datagram options.
    #  pkt = PacketGen.gen('IP')
    #  # add option from class
    #  pkt.ip.options << PacketGen::Header::IP::RA.new
    #  # or use a hash
    #  pkt.ip.options << { type: 'RR', data: ['192.168.16.4']}
    # @author Sylvain Daubert
    class IP < Base; end

    require_relative 'ip/addr'
    require_relative 'ip/option'
    require_relative 'ip/options'

    class IP
      # IP Ether type
      ETHERTYPE = 0x0800

      # @!attribute u8
      #  First byte of IP header. May be accessed through {#version} and {#ihl}.
      #  @return [Integer] first byte of IP header.
      define_field :u8, Types::Int8, default: 0x45
      # @!attribute tos
      #   @return [Integer] 8-bit Type of Service self[attr]
      define_field :tos, Types::Int8, default: 0
      # @!attribute length
      #   @return [Integer] 16-bit IP total length
      define_field :length, Types::Int16, default: 20
      # @!attribute id
      #   @return [Integer] 16-bit ID
      define_field :id, Types::Int16, default: ->(_) { rand(65_535) }
      # @!attribute frag
      #   @return [Integer] 16-bit frag word
      define_field :frag, Types::Int16, default: 0
      # @!attribute ttl
      #   @return [Integer] 8-bit Time To Live self[attr]
      define_field :ttl, Types::Int8, default: 64
      # @!attribute protocol
      #   @return [Integer] 8-bit upper protocol self[attr]
      define_field :protocol, Types::Int8
      # @!attribute checksum
      #   @return [Integer] 16-bit IP header checksum
      define_field :checksum, Types::Int16, default: 0
      # @!attribute src
      #   @return [Addr] source IP address
      define_field :src, Addr, default: '127.0.0.1'
      # @!attribute dst
      #   @return [Addr] destination IP address
      define_field :dst, Addr, default: '127.0.0.1'
      # @!attribute options
      #  @since 2.2.0
      #  @return [Types::String]
      define_field :options, Options, optional: ->(h) { h.ihl > 5 },
                                      builder: ->(h, t) { t.new(length_from: -> { (h.ihl - 5) * 4 }) }
      # @!attribute body
      #  @return [Types::String,Header::Base]
      define_field :body, Types::String

      # @!attribute version
      #   @return [Integer] 4-bit version attribute
      # @!attribute ihl
      #   @return [Integer] 4-bit IP header length attribute
      define_bit_fields_on :u8, :version, 4, :ihl, 4

      # @!attribute flag_rsv
      #   @return [Boolean] reserved bit from flags
      # @!attribute flag_df
      #   @return [Boolean] Don't Fragment flag
      # @!attribute flag_mf
      #   @return [Boolean] More Fragment flags
      # @!attribute fragment_offset
      #   @return [Integer] 13-bit fragment offset
      define_bit_fields_on :frag, :flag_rsv, :flag_df, :flag_mf, :fragment_offset, 13

      # Helper method to compute sum of 16-bit words. Used to compute IP-style
      # checksums.
      # @param [#to_s] hdr header or other object on which calculates a sum
      #   of 16-bit words.
      # @return [Integer]
      def self.sum16(hdr)
        old_checksum = nil
        if hdr.respond_to? :checksum=
          old_checksum = hdr.checksum
          hdr.checksum = 0
        end

        data = hdr.to_s
        data << "\x00" if data.size.odd?
        sum = data.unpack('n*').sum

        hdr.checksum = old_checksum if old_checksum

        sum
      end

      # Helper method to reduce an IP checksum.
      # This method:
      # * checks a checksum is not greater than 0xffff. If it is,
      #   reduces it.
      # * inverts reduced self[attr].
      # * forces self[attr] to 0xffff if computed self[attr] is 0.
      # @param [Integer] checksum checksum to reduce
      # @return [Integer] reduced checksum
      def self.reduce_checksum(checksum)
        checksum = (checksum & 0xffff) + (checksum >> 16) while checksum > 0xffff
        checksum = ~checksum & 0xffff
        checksum.zero? ? 0xffff : checksum
      end

      # Compute checksum and set +checksum+ field
      # @return [Integer]
      def calc_checksum
        # Checksum is only on header, so cannot use IP.sum16,
        # which also calculates checksum on #body.
        nb_words = ihl * 2
        self.checksum = 0
        checksum = to_s.unpack("n#{nb_words}").sum
        self[:checksum].value = IP.reduce_checksum(checksum)
      end

      # Compute and set +length+ and +ihl+ field
      # @return [Integer]
      # @since 3.0.0 add +ihl+ calculation
      def calc_length
        Base.calculate_and_set_length self
        self.ihl = 5 + self[:options].sz / 4
      end

      # Get IP part of pseudo header checksum.
      # @return [Integer]
      def pseudo_header_checksum
        checksum = self[:src].to_i + self[:dst].to_i
        (checksum >> 16) + (checksum & 0xffff)
      end

      # Send IP packet on wire.
      #
      # When sending packet at IP level, +checksum+ and +length+ fields are set by
      # kernel, so bad IP packets cannot be sent this way. To do so, use {Eth#to_w}.
      # @param [String,nil] _iface interface name. Not used
      # @return [void]
      def to_w(_iface=nil)
        sock = Socket.new(Socket::AF_INET, Socket::SOCK_RAW, Socket::IPPROTO_RAW)
        sockaddrin = Socket.sockaddr_in(0, dst)
        sock.send to_s, 0, sockaddrin
        sock.close
      end

      # @return [String]
      def inspect
        super do |attr|
          case attr
          when :u8
            inspect_u8
          when :frag
            inspect_frag
          end
        end
      end

      # Check version field
      # @see [Base#parse?]
      def parse?
        (version == 4) && (ihl >= 5)
      end

      # Get binary string. Fixup IHL if needed (IP header has options, and IHL
      # was not set by user).
      def to_s
        self.ihl = 5 + self[:options].sz / 4 if self.ihl == 5
        super
      end

      # Invert source and destination addresses
      # @return [self]
      # @since 2.7.0
      def reply!
        self[:src], self[:dst] = self[:dst], self[:src]
        self
      end

      private

      def inspect_u8
        shift = Inspect.shift_level
        str = Inspect.inspect_attribute(:u8, self[:u8])
        str << shift << Inspect::FMT_ATTR % ['', 'version', version]
        str << shift << Inspect::FMT_ATTR % ['', 'ihl', ihl]
      end

      def inspect_frag
        shift = Inspect.shift_level
        str = Inspect.inspect_attribute(:frag, self[:frag])
        flags = %i[rsv df mf].select { |flag| send(:"flag_#{flag}?") }.map(&:upcase)
        flags_str = flags.empty? ? 'none' : flags.join(',')
        str << shift << Inspect::FMT_ATTR % ['', 'flags', flags_str]
        foff = Inspect.int_dec_hex(fragment_offset, 4)
        str << shift << Inspect::FMT_ATTR % ['', 'frag_offset', foff]
      end
    end

    self.add_class IP

    Eth.bind IP, ethertype: IP::ETHERTYPE
    SNAP.bind IP, proto_id: IP::ETHERTYPE
    Dot1q.bind IP, ethertype: IP::ETHERTYPE
    IP.bind IP, protocol: 4
  end
end
