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


def main(event, context):
    secret = get_parameter('secret')
    print('fetched secret from SSM Parameter Store')
    random_message = ''.join(random.choice(string.ascii_lowercase) for num in range(10))

    message_data = [
        [datetime.datetime.utcnow().timestamp(), random_message]
    ]
    if Properties.storage_type == 'csv':
        print("csv")
        write_result(Properties.write_to_aws, Properties.s3_bucket, message_data)
    elif Properties.storage_type == 'postgres':
        print("postgres")
        engine = SqlAlchemyEngine.rds_engine() if Properties.write_to_aws else SqlAlchemyEngine.local_engine_maker()
        Base.metadata.create_all(engine.db_client)
        session = engine.scoped_session_maker()
        message_dao = MessageDao()
        message_dao.save(session=session, commit=True, popo=Message(message=random_message))
    else:
        raise Exception('storage_type must be either "postgres" or "csv".')

    return {
        'message': random_message,
        'secret': secret
    }


if __name__ == '__main__':
    main(None, None)