module ODBCAdapter
  # Caches SQLGetInfo output
  class DBMS
    CONFIG = YAML.load_file(File.expand_path(File.join('dbms', 'config.yml'), __dir__))

    FIELDS = [
      ODBC::SQL_DBMS_NAME,
      ODBC::SQL_DBMS_VER,
      ODBC::SQL_IDENTIFIER_CASE,
      ODBC::SQL_QUOTED_IDENTIFIER_CASE,
      ODBC::SQL_IDENTIFIER_QUOTE_CHAR,
      ODBC::SQL_MAX_IDENTIFIER_LEN,
      ODBC::SQL_MAX_TABLE_NAME_LEN,
      ODBC::SQL_USER_NAME,
      ODBC::SQL_DATABASE_NAME
    ]

    attr_reader :connection, :fields

    def initialize(connection)
      @connection = connection
      @fields     = Hash[FIELDS.map { |field| [field, connection.get_info(field)] }]
    end

    def config_for(field)
      CONFIG[name][field]
    end

    def ext_module
      @ext_module ||=
        begin
          require "odbc_adapter/dbms/#{name.downcase}_ext"
          DBMS.const_get(:"#{name}Ext")
        end
    end

    def visitor(adapter)
      ext_module::BindSubstitution.new(adapter)
    end

    private

    # Maps a DBMS name to a symbol
    # Different ODBC drivers might return different names for the same DBMS
    def name
      @name ||=
        case fields[ODBC::SQL_DBMS_NAME].downcase.gsub(/\s/, '')
        when /my.*sql/i      then :MySQL
        when /oracle/i       then :Oracle
        when /postgres/i     then :PostgreSQL
        else
          raise ArgumentError, "ODBCAdapter: Unsupported database (#{name})"
        end
    end
  end
end
