require_relative '../test_helper'

describe MySQLBinUUID::Type::Data do

  it "is of kind ActiveModel::Type::Binary::Data" do
    assert_kind_of ActiveModel::Type::Binary::Data, MySQLBinUUID::Type::Data.new(nil)
  end

  it "returns the raw value as hex value" do
    assert_equal "e7db0d1a", MySQLBinUUID::Type::Data.new("e7db0d1a").hex
  end

end
