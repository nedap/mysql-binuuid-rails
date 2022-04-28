require_relative '../test_helper'

module MySQLBinUUID
  class TypeTest < ActiveSupport::TestCase
    setup do
      @type = MySQLBinUUID::Type.new
    end

    test "#type reports :uuid as its type" do
      assert_equal :uuid, @type.type
    end

    test "#cast returns a dashed uuid if provided with a MySQLBinUUID::Type::Data" do
      uuid = "c5997c21-3355-4603-9e41-4fdc7194fe2d"
      data = MySQLBinUUID::Type::Data.new(uuid)

      assert_equal uuid, @type.cast(data)
    end

    test "#cast returns a dashed uuid if provided with a binary string" do
      uuid = "6d7c7ff2-dca8-45eb-b3a0-3b9a24a5270e"
      binstring = [uuid.delete("-")].pack("H*")
      binstring.force_encoding("ASCII-8BIT")
      assert_equal uuid, @type.cast(binstring)
    end

    test "#cast returns the value itself if provided with something else" do
      assert_equal 42, @type.cast(42)
    end

    test "#cast returns a uuid if provided with a uuid" do
      uuid = SecureRandom.uuid.encode(Encoding::ASCII_8BIT)
      data = MySQLBinUUID::Type.new.cast(uuid)

      assert_equal uuid, @type.cast(data)
    end

    test "#serialize returns nil if provided with nil (touché)" do
      assert_nil @type.serialize(nil)
    end

    test "#serialize returns a MySQLBinUUID::Type::Data with stripped values if provided with a UUID" do
      uuid = "3511f33f-3c93-4806-9846-52b4a7618298"

      assert_instance_of MySQLBinUUID::Type::Data, @type.serialize(uuid)
      assert_equal "3511f33f3c934806984652b4a7618298", @type.serialize(uuid).to_s
    end
  end
end
