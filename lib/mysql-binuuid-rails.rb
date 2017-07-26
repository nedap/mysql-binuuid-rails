require 'mysql-binuuid/type'

ActiveModel::Type.register(:uuid, MySQLBinUUID::Type)

module MySQLBinUUID
end
