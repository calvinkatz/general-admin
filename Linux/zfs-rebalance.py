# Basic ZFS rebalance script.
# Copy file to temporary name and then overwrite the original with temp.
# Run at least two times to balance old data.

import glob, os, shutil, subprocess, logging, sys, argparse
from datetime import datetime

parser = argparse.ArgumentParser(description='Rebalance ZFS pool')
parser.add_argument('-p', '--path', help='Path to reblance', type=str, action='store')
args = parser.parse_args()
dir = args.path
if os.path.isdir(dir):
    print('Starting rebalance on: ' + dir)
else:
    print('Path not found!')
    sys.exit()

# current date and time
now = datetime.now()
# H-M-S_dd-mm-YY
dt_string = now.strftime('%m-%d-%Y_%H-%M')

# create logger with 'spam_application'
logger = logging.getLogger('zfs-rebalance')
logger.setLevel(logging.INFO)
# create file handler which logs even debug messages
fh = logging.FileHandler('/tmp/rebalance_' + dt_string + '.log')
fh.setLevel(logging.INFO)
# create console handler with a higher log level
ch = logging.StreamHandler()
ch.setLevel(logging.ERROR)
# create formatter and add it to the handlers
formatter = logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s')
fh.setFormatter(formatter)
ch.setFormatter(formatter)
# add the handlers to the logger
logger.addHandler(fh)
logger.addHandler(ch)

logger.info('STARTING')
logger.info('Working: ' + dir)
logger.info('Generating iterator')
iter = glob.iglob((dir + '/**'), recursive=True)

for item in iter:
    if not os.path.islink(item) and os.path.isfile(item):
        logger.info('Item: ' + item)
        temp = item + '.ZFS'
        logger.info('Temp: ' + temp)
        logger.info('Moving Item to Temp.')
        print('Moving: ' + item)
        shutil.copy2(item, temp)
        logger.info('Replacing Item with Temp.')
        os.replace(temp, item)
print('')
logger.info('FINISHED')
print('Done!')
