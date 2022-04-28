require_relative '../test_helper'

module MySQLBinUUID
  class Type
    class DataTest < ActiveSupport::TestCase
      test "is of kind ActiveModel::Type::Binary::Data" do
        assert_kind_of ActiveModel::Type::Binary::Data, MySQLBinUUID::Type::Data.new(nil)
      end

      test "returns the raw value as hex value" do
        assert_equal "e7db0d1a", MySQLBinUUID::Type::Data.new("e7db0d1a").hex
      end
    end
  end
end
