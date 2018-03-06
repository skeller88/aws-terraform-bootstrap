import datetime
from sqlalchemy import Integer, String, CHAR, Column, Float, BigInteger

from src.message import Message
from src.storage.sql_alchemy_dtos.base import Base


class SqlAlchemyMessageDto(Base):
    """
    """
    __tablename__ = 'messages'

    db_id = Column(BigInteger,  autoincrement=True, primary_key=True)
    message = Column(String, nullable=False)
    created_at = Column(Float, default=datetime.datetime.utcnow().timestamp, nullable=False)
    updated_at = Column(Float, default=datetime.datetime.utcnow().timestamp, nullable=False)
    version = Column(Integer, nullable=False)

    def to_popo(self):
        return Message(db_id=self.db_id, message=self.message, created_at=self.created_at, updated_at=self.updated_at)

    @staticmethod
    def from_popo(popo):
        return SqlAlchemyMessageDto(db_id=popo.db_id, message=popo.message, created_at=popo.created_at,
                                    updated_at=popo.updated_at, version=popo.version)
