from src.storage.daos.dao import Dao
from src.storage.sql_alchemy_dtos.sql_alchemy_message_dto import SqlAlchemyMessageDto


class MessageDao(Dao):
    def __init__(self):
        super().__init__(dto_class=SqlAlchemyMessageDto)