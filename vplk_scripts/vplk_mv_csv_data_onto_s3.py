import boto3
import logging
import os
import sys

logger = logging.getLogger(__name__)
logging.basicConfig(stream=sys.stdout, level=logging.INFO)


def list_dir_files(dir):
     return os.listdir(dir)


def remove_file(filepath):
    os.remove(filepath)


def upload_file_onto_s3(dirpath, bucket, folder):

    logger.info("Check if there is exists any file in \"{}\" dir path".format(dirpath))
    files_list = list_dir_files(dir=dirpath)
    if len(files_list) > 0 :
        s3 = boto3.resource('s3')
        try:
            for file in files_list:
                logger.info("Moving file {} onto \"{}\" s3 location".format(file, bucket))
                filepath = "{}/{}".format(dirpath, file)
                s3.meta.client.upload_file(Filename=filepath, Bucket=bucket, Key=folder+'/'+file)
                logger.info("Removing file {} from \"{}\" dir path".format(file, dirpath))
                remove_file(filepath=filepath)
        except:
            logger.error("Error occurred while uploading onto \"{}\" s3 location".format(bucket))
            raise
    else:
        logger.info("No csv file yet found in \"{}\" dir path, skipping...".format(dirpath))


# Main function
if __name__ == "__main__":

    print(len(sys.argv))
    if len(sys.argv) > 0 and len(sys.argv) == 4:
        bucket_name = sys.argv[1]
        dirpath = sys.argv[2]
        folder = sys.argv[3]
        upload_file_onto_s3(dirpath=dirpath
                            ,bucket=bucket_name
                            ,folder=folder)
    else:
        logger.error("One of the arguments is missing!")