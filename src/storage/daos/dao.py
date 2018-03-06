class Dao:
    def __init__(self, dto_class):
        self.dto_class = dto_class

    # Create
    def save(self, session, flush=False, commit=False, popo=None):
        try:
            dto = self.dto_class.from_popo(popo)
            session.add(dto)

            if flush:
                session.flush()
            if commit:
                session.commit()

            return session, dto.to_popo()
        except Exception as exception:
            print('rolling back due to exception')
            session.rollback()
            raise exception

    # Read
    def fetch_by_db_id(self, session, db_id):
        try:
            dto = session.query(self.dto_class).filter_by(db_id=db_id).first()

            if dto is not None:
                return session, dto.to_popo()

            return session, None
        except Exception as exception:
            print('rolling back due to exception')
            session.rollback()
            raise exception

    # Delete
    def delete(self, session, db_id, flush=False, commit=False):
        try:
            deleted_count = session.query(self.dto_class).filter_by(db_id=db_id).delete()

            if flush:
                session.flush()
            if commit:
                session.commit()

            return session, deleted_count
        except Exception as exception:
            print('rolling back due to exception')
            session.rollback()
            raise exception
