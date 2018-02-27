# This file is part of PacketGen
# See https://github.com/sdaubert/packetgen for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# This program is published under MIT license.
require_relative 'mcast_address_record'

module PacketGen
  module Header
    module MLDv2
      # This class supports MLDv2 Multicast Listener Report messages.
      #
      # From RFC 3810, a MLDv2 Multicast Listener Report message has the
      # following format:
      #   0                   1                   2                   3
      #   0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |  Type = 143   |    Reserved   |           Checksum            |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |           Reserved            |Nr of Mcast Address Records (M)|
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |                                                               |
      #   .                                                               .
      #   .                  Multicast Address Record [1]                 .
      #   .                                                               .
      #   |                                                               |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |                               .                               |
      #   .                               .                               .
      #   |                               .                               |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |                                                               |
      #   .                                                               .
      #   .                  Multicast Address Record [M]                 .
      #   .                                                               .
      #   |                                                               |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      # +type+, +code+ and +checksum+ are fields from {ICMPv6} header.
      #
      # MLR fields are:
      # * {#reserved} ({Types::Int16}),
      # * {#number_of_mar} (number of mcast address records, {Types::Int16}),
      # * {#records} ({McastAddressRecords}).
      # @author Sylvain Daubert
      class MLR < Base
        # @!attribute reserved
        #  16-bit reserved field
        # @return [Integer]
        define_field :reserved, Types::Int16, default: 0
        # @!attribute number_of_mar
        #  16-bit Number of group records in {#records}
        #  @return [Integer]
        define_field :number_of_mar, Types::Int16, default: 0
        
        # @!attribute records
        #  Array of Mcast Address Records
        #  @return [McastAddressRecords]
        define_field :records, McastAddressRecords,
                     builder: ->(h, t) { t.new(counter: h[:number_of_mar]) }
      end
    end
    
    self.add_class MLDv2::MLR
    ICMPv6.bind_header MLDv2::MLR, type: 143
  end
end
