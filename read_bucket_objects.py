import sys

from src.storage.s3 import read_bucket_objects

if __name__ == '__main__':
    read_bucket_objects(sys.argv[1])
