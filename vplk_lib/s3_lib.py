import boto3
import logging
import sys
import os
from datetime import datetime

logger = logging.getLogger(__name__)
logging.basicConfig(stream=sys.stdout, level=logging.INFO)


def get_filename(filepath):
    return os.path.basename(filepath)


# The purpose of this subroutine is to read all the files from s3 bucket
# from a specified source directory
def s3_get_files(bucket_name, region, source_dir):
    s3 = boto3.client('s3', region)
    files_list = []
    try:
        response = s3.list_objects(Bucket=bucket_name, Prefix=source_dir+'/')
        for file in response['Contents']:
            file_name = get_filename(filepath=file['Key'])
            files_list.append(file_name)

        return files_list
    except:
        logger.error("Error has occurred while getting file")
        raise


# The purpose of this subroutine is to read all the files from s3 bucket
# from a specified source directory
def s3_read_files(bucket_name, region, source_dir):

    s3 = boto3.client('s3', region)
    files_list = []
    try:
        response = s3.list_objects(Bucket=bucket_name, Prefix=source_dir+'/')
        for file in response['Contents']:
            obj = s3.get_object(Bucket=bucket_name, Key=file['Key'])
            if obj is not None:
                file_name = get_filename(filepath=file['Key'])
                file_struct = {
                    "file": file_name,
                    "data": obj['Body']
                }
                files_list.append(file_struct)
        return files_list
    except:
        logger.error("Error has occurred while reading file")
        return files_list


# The purpose of this subroutine is to delete the file from s3 bucket
def s3_delete_file(bucket_name, region, source_dir, file):

    client = boto3.client('s3', region)
    try:
        client.delete_object(Bucket=bucket_name,
                             Key="{}/{}".format(source_dir, file))
    except:
        logger.error("Error has occurred while deleting file")
        raise


# The purpose of this subroutine is to move all the processed files in s3 bucket
# from source directory to target directory
def s3_move_files(bucket_name, region, source_dir, target_dir):

    s3 = boto3.resource('s3', region)
    today_fmt = datetime.today().strftime('%Y%m%d')

    try:

        for file in s3_get_files(bucket_name=bucket_name,
                                 region=region,
                                 source_dir=source_dir):
            copy_source = {
                "Bucket": bucket_name,
                "Key": "{}/{}".format(source_dir, file)
            }
            s3.meta.client.copy(copy_source, bucket_name, "{}/{}/{}".format(target_dir, today_fmt, file))
            s3_delete_file(bucket_name=bucket_name,
                           region=region,
                           source_dir=source_dir,
                           file=file)
    except:
        logger.error("Error has occurred while moving file")
        raise
