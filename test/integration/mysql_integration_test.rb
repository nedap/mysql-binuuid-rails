require 'rails/all'
require 'minitest/hooks'
require 'securerandom'

require_relative '../test_helper'

class MyUuidModel < ActiveRecord::Base
  attribute :the_uuid, MySQLBinUUID::Type.new
end

describe MyUuidModel do
  include Minitest::Hooks

  def connection
    ActiveRecord::Base.connection
  end

  let(:db_config) do
    { adapter:  'mysql2',
      host:     'localhost',
      username: 'root',
      password: '',
      database: 'binuuid_rails_test' }
  end

  before(:all) do
    db_config_without_db_name = db_config.dup
    db_config_without_db_name.delete(:database)

    # Create a connection without selecting a database first to create the db
    ActiveRecord::Base.establish_connection(db_config_without_db_name)
    connection.create_database(db_config[:database])

    # Then establish a new connection with the database name
    ActiveRecord::Base.establish_connection(db_config)
    connection.create_table("my_uuid_models")
    connection.add_column("my_uuid_models", "the_uuid", :binary, limit: 16)

    # Uncomment this line to get logging on stdout
    # ActiveRecord::Base.logger = Logger.new(STDOUT)
  end

  after(:all) do
    connection.drop_database(db_config[:database])
  end

  let(:sample_uuid) { SecureRandom.uuid }

  context "without saving" do
    it "does not change the uuid when retrieved without saving" do
      my_model = MyUuidModel.new(the_uuid: sample_uuid)
      assert_equal sample_uuid, my_model.the_uuid
      assert_equal sample_uuid, my_model.attributes["the_uuid"]
    end
  end

  context "before saving" do
    describe "rails validation" do

      class MyUuidModelWithValidations < MyUuidModel
        validates :the_uuid, uniqueness: true
      end

      it "validates uniqueness" do
        skip("Skipping uniqueness validation test, known issue on Rails 5.0") if Rails.version < "5.1"

        uuid = sample_uuid
        MyUuidModelWithValidations.create!(the_uuid: uuid)
        duplicate = MyUuidModelWithValidations.new(the_uuid: uuid)

        assert_equal false, duplicate.valid?
        assert_equal :taken, duplicate.errors.details[:the_uuid].first[:error]
      end

    end
  end

  context "after persisting to the database" do
    before do
      @my_model = MyUuidModel.create!(the_uuid: sample_uuid)
    end

    after do
      MyUuidModel.delete_all
    end

    it "stores a binary value in the database" do
      raw_value = connection.execute("SELECT * FROM my_uuid_models").to_a.first[1]
      assert_equal raw_value.encoding, Encoding::ASCII_8BIT
    end

    it "stores a binary value without dashes" do
      raw_value = connection.execute("SELECT * FROM my_uuid_models").to_a.first[1]

      # Create a version without dashes of the sample uuid
      sample_uuid_no_dashes = sample_uuid.delete("-")

      # Put it in an array so we can create the binary representation we
      # also get from the database.
      assert_equal [sample_uuid_no_dashes].pack("H*"), raw_value
    end

    it "can be found using .find_by" do
      find_result = MyUuidModel.find_by(the_uuid: sample_uuid)
      assert_equal find_result, @my_model
      assert_equal find_result.the_uuid, sample_uuid
    end

    it "can be found using .where" do
      results = MyUuidModel.where(the_uuid: sample_uuid)
      assert_equal results.count, 1
      assert_equal results.first, @my_model
      assert_equal results.first.the_uuid, sample_uuid
    end
  end

end
