import datetime

import requests

from src.message import Message
from src.ssm_methods import get_parameter
from src.properties import Properties
from src.storage.daos.message_dao import MessageDao
from src.storage.s3 import write_result
from src.storage.sql_alchemy_dtos.base import Base
from src.storage.sql_alchemy_engine import SqlAlchemyEngine

fake_json_endpoint = 'https://jsonplaceholder.typicode.com/posts/1'
dummy_secret = 'dummy_secret'


def hello_world(event=None, context=None):
    """
    Reads a parameter from Parameter Store, makes a HTTPS request to a [fake online REST API](https://jsonplaceholder.typicode.com/),
    and, depending on the environment variables, writes part of the response from the fake REST API to a csv file or Postgres, hosted
    either locally or on AWS. The csv file is either in a local directory:

    `<aws-terraform-bootstrap-dir>/data/<timestamp>_message.csv>`

    or an AWS bucket:

    `hello-world-<hello_world_bucket_name_suffix>/<timestamp>_message.csv`

    The Postgres database is either a local Postgres instance:

    `$ psql --dbname=hello_world --user=hellorole --host=localhost`

    or a Postgres instance hosted on a RDS host:

    Args:
        event: AWS e
        context:

    Returns:
        dict: contains
            message (str): title of message fetched from jsonplaceholder.typicode.com
            secret (str): secret fetched from SSM or dummy secret

    """
    if Properties.use_aws:
        secret = get_parameter('secret')
        print('fetched secret from SSM Parameter Store', secret)
    else:
        secret = dummy_secret

    response = requests.get(fake_json_endpoint).json()
    print('fetched message from the internet', response['title'])

    if Properties.storage_type == 'csv':
        print("storage_type is 'csv'")
        message_data = [
            [datetime.datetime.utcnow().timestamp(), response['title']]
        ]
        write_result(Properties.use_aws, Properties.s3_bucket, message_data)
    elif Properties.storage_type == 'postgres':
        print("storage_type is 'postgres'")
        engine = SqlAlchemyEngine.engine()
        Base.metadata.create_all(engine.db_client)
        session = engine.scoped_session_maker()
        message_dao = MessageDao()
        print('writing to database')
        message_dao.save(session=session, commit=True, popo=Message(message=response['title']))
    else:
        raise Exception('storage_type must be either "postgres" or "csv".')

    response = {
        'message': response['title'],
        'secret': secret
    }
    print('hello_world response: ', response)
    return response