import datetime
import random
import string

import requests

from src.hello_world import hello_world
from src.message import Message
from src.ssm_methods import get_parameter
from src.properties import Properties
from src.storage.daos.message_dao import MessageDao
from src.storage.s3 import write_result
from src.storage.sql_alchemy_dtos.base import Base
from src.storage.sql_alchemy_engine import SqlAlchemyEngine

fake_json_endpoint = 'https://jsonplaceholder.typicode.com/posts/1'


def main(event=None, context=None):
    hello_world(event, context)


if __name__ == '__main__':
    main(None, None)