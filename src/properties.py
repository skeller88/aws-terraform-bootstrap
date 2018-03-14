import os


class Properties:
    """
    Provides a single interface for accessing environment variables, and makes it easy to identify which environment
    variables are being used.
    """
    # query AWS or local resources
    use_aws = os.environ.get('USE_AWS') == 'True'

    # use csv or postgres for app storage
    # accepted values are 'postgres' or 'csv'
    storage_type = os.environ.get('STORAGE_TYPE')

    # if using AWS resources,
    s3_bucket = os.environ.get('S3_BUCKET')
    # 'False' will evaluate to bool(True) otherwise

    ## postgres
    db_host_address = os.environ.get('DB_HOST_ADDRESS', 'localhost')
    db_password = os.environ.get('DB_PASSWORD')
