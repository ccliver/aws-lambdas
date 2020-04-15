import boto3
import PIL
import os

def create_thumbnail(img):
    width   = int(os.environ['THUMBNAIL_WIDTH'])
    height  = int(os.environ['THUMBNAIL_HEIGHT'])

    try:
        with PIL.Image.open(img) as im:
            outfile = os.path.splitext(img)[0] + ".thumbnail." + im.format)
            im.thumbnail((width, height))
            im.save(outfile, im.format)
    except IOError as e:
        print("Error creating thumbnail for", img, e)

def lambda_handler(event, context):
    print(event)
