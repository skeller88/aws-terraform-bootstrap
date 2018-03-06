class Message:
    def __init__(self, message, db_id=None, created_at=None, updated_at=None, version=0):
        self.db_id = db_id
        self.message = message
        self.created_at = created_at
        self.updated_at = updated_at
        self.version = version