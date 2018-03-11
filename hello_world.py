import datetime
import random
import string

import requests

from src.message import Message
from src.methods import get_parameter
from src.properties import Properties
from src.storage.daos.message_dao import MessageDao
from src.storage.s3 import write_result
from src.storage.sql_alchemy_dtos.base import Base
from src.storage.sql_alchemy_engine import SqlAlchemyEngine

fake_json_endpoint = 'https://jsonplaceholder.typicode.com/posts/1'


def main(event=None, context=None):
    if Properties.use_aws:
        secret = get_parameter('secret')
        print('fetched secret from SSM Parameter Store', secret)
    else:
        secret = 'dummy_secret'

    response = requests.get(fake_json_endpoint).json()
    print('fetched message from the internet:', response)

    if Properties.storage_type == 'csv':
        print("storage_type is 'csv'")
        data = [
            [datetime.datetime.utcnow().timestamp(), response['title']]
        ]
        write_result(Properties.use_aws, Properties.s3_bucket, data)
    elif Properties.storage_type == 'postgres':
        print("storage_type is 'postgres'")
        engine = SqlAlchemyEngine.rds_engine() if Properties.use_aws else SqlAlchemyEngine.local_engine_maker()
        Base.metadata.create_all(engine.db_client)
        session = engine.scoped_session_maker()
        message_dao = MessageDao()
        print('writing to database')
        message_dao.save(session=session, commit=True, popo=Message(message=response['title']))
    else:
        raise Exception('storage_type must be either "postgres" or "csv".')

    return {
        'message': response['title'],
        'response': response,
        'secret': secret
    }


if __name__ == '__main__':
    main(None, None)