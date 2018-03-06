class Database(object):
    """
    Based on code here:
    https://softwareengineering.stackexchange.com/questions/200522/how-to-deal-with-database-connections-in-a-python-library-module

    Create a new cursor for each transaction, but reuse the connection:
    https://stackoverflow.com/questions/8099902/should-i-reuse-the-cursor-in-the-python-mysqldb-module

    Use ('line1 '\n'line2') for query string formatting:
    https://stackoverflow.com/questions/5243596/python-sql-query-string-formatting
    """
    db_connection = None
    db_cursor = None

    def __init__(self, database_module, **kwargs):
        print('connecting to database at address {0}'.format(kwargs.get('host')))
        self.db_connection = database_module.connect(**kwargs)
        self.db_cursor = self.db_connection.cursor()

    def cursor(self):
        return self.db_cursor

    def query(self, query, params=None):
        return self.db_cursor.execute(query, params)

    def __del__(self):
        self.db_connection.close()
