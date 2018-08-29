# This file is part of PacketGen
# See https://github.com/sdaubert/packetgen for more informations
# Copyright (C) 2016 Sylvain Daubert <sylvain.daubert@laposte.net>
# This program is published under MIT license.

# frozen_string_literal: true

module PacketGen
  module Header
    class OSPFv2
      # This class handles {OSPFv2 OSPFv2} DB description packets payload.
      # The DB description payload has the following format:
      #    0                   1                   2                   3
      #    0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |         Interface MTU         |    Options    |0|0|0|0|0|I|M|MS
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |                     DD sequence number                        |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |                                                               |
      #   +-                                                             -+
      #   |                                                               |
      #   +-                      An LSA Header                          -+
      #   |                                                               |
      #   +-                                                             -+
      #   |                                                               |
      #   +-                                                             -+
      #   |                                                               |
      #   +-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
      #   |                              ...                              |
      #
      # A DB description payload is composed of:
      # * a 16-bit {#mtu} field ({Types::Int16}),
      # * a 8-bit {#options} field ({Types::Int8}),
      # * a 8-bit {#flags} field ({Types::Int8}). Supported flags are:
      #   * {i_flag},
      #   * {m_flag},
      #   * {ms_flag},
      # * a 32-bit {#sequence_number} field ({Types::Int32}),
      # * and an array of {LSAHeader LSAHeaders} ({#lsas}, {ArrayOfLSA}).
      #
      # == Create a DbDescription payload
      #   # standalone
      #   dbd = PacketGen::Header::OSPFv2::DbDescription.new
      #   # in a packet
      #   pkt = PacketGen.gen('IP', src: source_ip).add('OSPFv2').add('OSPFv2::DbDescription')
      #   # access to DbDescription payload
      #   pkt.ospfv2_dbdescription    # => PacketGen::Header::OSPFv2::DbDescription
      #
      # == DbDescription attributes
      #   dbd.mtu = 1500
      #   # set options. Options may also be set one by one with {#mt_opt},
      #   # {#e_opt}, {#mc_opt}, {#n_opt}, {#l_opt}, {#dc_opt}, {#o_opt} and {#dn_opt}
      #   dbd.options = 0
      #   dbd.flags = 0
      #   dbd.seqnum = 0x800001
      #   # add a LSA Router header
      #   dbd.lsas << { type: 'Router', age: 40, link_state_id: '0.0.0.1', advertising_router: '1.1.1.1', sequence_number: 42, checksum: 0x1234, length: 56 }
      #   # a header may also be set from an existing lsa
      #   dbd.lsas << existing_lsa.to_lsa_header
      # @author Sylvain Daubert
      class DbDescription < Base
        # @!attribute mtu
        #  16-bit interface MTU
        #  @return [Integer]
        define_field :mtu, Types::Int16

        # @!macro define_options
        OSPFv2.define_options(self)

        # @!attribute flags
        #  8-bit interface flags ({#i_flag}, {#m_flag} and {#ms_flag})
        #  @return [Integer]
        define_field :flags, Types::Int8
        # @!attribute i_flag
        #  Init bit
        #  @return [Boolean]
        # @!attribute m_flag
        #  More bit
        #  @return [Boolean]
        # @!attribute ms_flag
        #  Master/Slave bit
        #  @return [Boolean]
        define_bit_fields_on :flags, :zero, 5, :i_flag, :m_flag, :ms_flag

        # @!attribute sequence_number
        #  32-bit DD sequence number, used to sequence the collection of Database
        #  Description Packets.
        #  @return [Integer]
        define_field :sequence_number, Types::Int32
        alias seqnum sequence_number
        alias seqnum= sequence_number=

        # @!attribute lsas
        #  Array of LSA headers
        #  @return [ArrayOfLSAHeader]
        define_field :lsas, ArrayOfLSA, builder: ->(_h, t) { t.new(only_headers: true) }
      end
    end

    self.add_class OSPFv2::DbDescription
    OSPFv2.bind OSPFv2::DbDescription, type: OSPFv2::TYPES['DB_DESCRIPTION']
  end
end
