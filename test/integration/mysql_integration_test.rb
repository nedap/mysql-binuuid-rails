require_relative '../test_helper'

class MyUuidModel < ActiveRecord::Base
  attribute :the_uuid, MySQLBinUUID::Type.new
end

class MyUuidModelWithValidations < MyUuidModel
  validates :the_uuid, uniqueness: true
end

class MySQLIntegrationTest < ActiveSupport::TestCase
  def connection
    ActiveRecord::Base.connection
  end

  def db_config
    {
      adapter:  "mysql2",
      host:     ENV["MYSQL_HOST"] || "localhost",
      username: ENV["MYSQL_USERNAME"] || "root",
      password: ENV["MYSQL_PASSWORD"] || "",
      database: "binuuid_rails_test"
    }
  end

  setup do
    db_config_without_db_name = db_config.dup
    db_config_without_db_name.delete(:database)

    # Create a connection without selecting a database first to create the db
    ActiveRecord::Base.establish_connection(db_config_without_db_name)
    connection.create_database(db_config[:database], charset: "utf8mb4")

    # Then establish a new connection with the database name
    ActiveRecord::Base.establish_connection(db_config)
    connection.create_table("my_uuid_models")
    connection.add_column("my_uuid_models", "the_uuid", :binary, limit: 16)

    # Uncomment this line to get logging on stdout
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
  end

  teardown do
    connection.drop_database(db_config[:database])
  end

  class BeforePersistedTest < MySQLIntegrationTest
    test "does not change the uuid when retrieved without saving" do
      sample_uuid = SecureRandom.uuid
      my_model = MyUuidModel.new(the_uuid: sample_uuid)
      assert_equal sample_uuid, my_model.the_uuid
      assert_equal sample_uuid, my_model.attributes["the_uuid"]
    end

    test "validates uniqueness" do
      uuid = SecureRandom.uuid
      MyUuidModelWithValidations.create!(the_uuid: uuid)
      duplicate = MyUuidModelWithValidations.new(the_uuid: uuid)

      assert_equal false, duplicate.valid?
      assert_equal :taken, duplicate.errors.details[:the_uuid].first[:error]
    end
  end

  class AfterPersistedTest < MySQLIntegrationTest
    setup do
      @sample_uuid = SecureRandom.uuid
      @my_model = MyUuidModel.create!(the_uuid: @sample_uuid)
    end

    teardown do
      MyUuidModel.delete_all
    end

    test "stores a binary value in the database" do
      raw_value = connection.execute("SELECT * FROM my_uuid_models").to_a.first[1]
      assert_equal raw_value.encoding, Encoding::ASCII_8BIT
    end

    test "stores a binary value without dashes" do
      raw_value = connection.execute("SELECT * FROM my_uuid_models").to_a.first[1]

      # Create a version without dashes of the sample uuid
      sample_uuid_no_dashes = @sample_uuid.delete("-")

      # Put it in an array so we can create the binary representation we
      # also get from the database.
      assert_equal [sample_uuid_no_dashes].pack("H*"), raw_value
    end

    test "can be found using .find_by" do
      find_result = MyUuidModel.find_by(the_uuid: @sample_uuid)
      assert_equal find_result, @my_model
      assert_equal find_result.the_uuid, @sample_uuid
    end

    test "can be found using .where" do
      results = MyUuidModel.where(the_uuid: @sample_uuid)
      assert_equal results.count, 1
      assert_equal results.first, @my_model
      assert_equal results.first.the_uuid, @sample_uuid
    end

    test "can't be used to inject SQL using .where" do
      # In Rails 7.1, the error gets wrapped in an ActiveRecord::StatementInvalid.
      expected_error = ActiveRecord.version.to_s.start_with?("7.1") ? ActiveRecord::StatementInvalid : MySQLBinUUID::InvalidUUID
      assert_raises(expected_error) do
        MyUuidModel.where(the_uuid: "' OR ''='").first
      end
    end

    test "can't be used to inject SQL using .find_by" do
      assert_raises MySQLBinUUID::InvalidUUID do
        MyUuidModel.find_by(the_uuid: "' OR ''='")
      end
    end

    test "can't be used to inject SQL while creating" do
      assert_raises MySQLBinUUID::InvalidUUID do
        MyUuidModel.create!(the_uuid: "40' + x'40")
      end
    end
  end
end
