import csv
import io

import os

import datetime

import boto3
import smart_open

header = ['datetime', 'message']


def write_result(write_to_aws, s3_bucket, rows):
    if write_to_aws:
        print('write_to_aws')
        second_timestamp = int(datetime.datetime.utcnow().replace(microsecond=0).timestamp())
        local_filename = '{0}_message.csv'.format(second_timestamp)
        with smart_open.smart_open('s3://{0}/{1}'.format(s3_bucket, local_filename), 'wb') as fout:
            print('writing to s3_bucket', s3_bucket)
            string_buffer = io.StringIO()
            writer = csv.writer(string_buffer)
            writer.writerow(header)

            fout.write(string_buffer.getvalue().encode('utf-8'))

            for row in rows:
                string_buffer.seek(0)
                string_buffer.truncate(0)

                writer.writerow(row)

                fout.write(string_buffer.getvalue().encode('utf-8'))
    else:
        local_dir = os.path.join(os.getcwd(), 'data')
        second_timestamp = int(datetime.datetime.utcnow().replace(microsecond=0).timestamp())
        local_filename = '{0}_message.csv'.format(second_timestamp)
        local_filepath = os.path.join(local_dir, local_filename)

        with open(local_filepath, 'w+') as csvfile:
            print('writing to local filepath', local_filepath)
            writer = csv.writer(csvfile)
            writer.writerow(header)
            for row in rows:
                writer.writerow(row)