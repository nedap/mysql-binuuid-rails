module MySQLBinUUID
  class Type < ActiveModel::Type::Binary

    def type
      :uuid
    end

    # Invoked when a value that is returned from the database needs to be
    # displayed into something readable again.
    def cast(value)
      if value.is_a?(MySQLBinUUID::Type::Data)
        # It could be a Data object, in which case we should add dashes to the
        # string value from there.
        add_dashes(value.to_s)
      elsif value.is_a?(String) && value.encoding == Encoding::ASCII_8BIT
        # We cannot unpack something that looks like a UUID, with or without
        # dashes. Not entirely sure why ActiveRecord does a weird combination of
        # cast and serialize before anything needs to be saved..
        undashed_uuid = value.unpack("H*")[0]
        add_dashes(undashed_uuid.to_s)
      else
        super
      end
    end

    # Invoked when the provided value needs to be serialized before storing
    # it to the database.
    def serialize(value)
      return if value.nil?
      Data.new(strip_dashes(value))
    end

    # We're inheriting from the Binary type since ActiveRecord in that case
    # will get the hex value. All we need to do to provide the hex value of the
    # UUID, is to return the UUID without dashes. And because this inherits
    # from Binary::Data, ActiveRecord will quote the hex value as required by
    # the database to store it.
    class Data < ActiveModel::Type::Binary::Data
      def initialize(value)
        @value = value
      end

      def hex
        @value
      end
    end

  private

    # A UUID consists of 5 groups of characters.
    #   8 chars - 4 chars - 4 chars - 4 chars - 12 characters
    #
    # This function re-introduces the dashes since we removed them during
    # serialization, so:
    #
    #   add_dashes("2b4a233152694c6e9d1e098804ab812b")
    #     => "2b4a2331-5269-4c6e-9d1e-098804ab812b"
    #
    def add_dashes(uuid)
      return uuid if uuid =~ /\-/
      [uuid[0..7], uuid[8..11], uuid[12..15], uuid[16..19], uuid[20..-1]].join("-")
    end

    # A UUID has 4 dashes is displayed with 4 dashes at the same place all
    # the time. So they don't add anything semantically. We can safely remove
    # them before storing to the database, and re-add them whenever we
    # retrieved a value from the database.
    #
    #   strip_dashes("2b4a2331-5269-4c6e-9d1e-098804ab812b")
    #     => "2b4a233152694c6e9d1e098804ab812b"
    #
    def strip_dashes(uuid)
      uuid.delete("-")
    end

  end
end
