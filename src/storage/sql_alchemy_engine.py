"""
Use pg8000 for the driver instead of psycopg2 because psycopg2 doesn't compile on lambda linux boxes:
 https://stackoverflow.com/questions/36607952/using-psycopg2-with-lambda-to-update-redshift-python/36608956#36608956,
 and I wasn't able to get the workaround library to work locally: https://github.com/jkehler/awslambda-psycopg2

Depends on SQLAlchemy logic. There wasn't a quick way to abstract that away yet. Ideally this class would be an
implmentation of some abstract class.

"""
import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, scoped_session

from src.properties import Properties
from src.storage.sql_alchemy_dtos.base import Base


class SqlAlchemyEngine:
    def __init__(self, dialect='postgres', driver='pg8000', username='hello_world', password=None, host='localhost',
                 port=5432, database='hello_world', echo=False, **kwargs):
        # dialect+driver://username:password@host:port/database
        self.connection_string = '{dialect}+{driver}://{username}:{password}@{host}:{port}/{database}'.format(**{
            'dialect': dialect,
            'driver': driver,
            'username': username,
            'password': password,
            'host': host,
            'port': port,
            'database': database
        })
        print('connecting to database at {0} on port {1}'.format(host, port))
        self.db_client = create_engine(self.connection_string, echo=echo, **kwargs)
        # sqlalchemy's API is confusingly named. Call session_maker to create a Session instance. Then Session is called
        # to create thread-local session instances. The "Session" object is actually the object that makes sessions.
        # http://docs.sqlalchemy.org/en/latest/orm/session_api.html#sqlalchemy.orm.session.Session
        session_maker_instance = sessionmaker(bind=self.db_client, autocommit=False, autoflush=False)
        self.scoped_session_maker = scoped_session(session_maker_instance)

    def dispose(self):
        """
        Closes all connections in the connection pool

        https://stackoverflow.com/questions/21738944/how-to-close-a-sqlalchemy-session
        :return:
        """
        self.db_client.dispose()

    def drop_tables(self):
        Base.metadata.drop_all(self.db_client)

    def update_tables(self):
        return Base.metadata.create_all(self.db_client)

    def initialize_tables(self):
        self.drop_tables()
        return Base.metadata.create_all(self.db_client)

    @classmethod
    def rds_engine(cls, **kwargs):
        return cls(dialect='postgres', driver='pg8000', username='hellorole',
                   password=Properties.prod_db_password, host=Properties.rds_host_address, port=5432, database='hello_world',
                   **kwargs)

    @classmethod
    def local_engine_maker(cls, **kwargs):
        return cls(dialect='postgres', driver='pg8000', username='hello_role',
                   password=Properties.local_db_password, host='localhost', port=5432,
                   database='hello_world', **kwargs)
