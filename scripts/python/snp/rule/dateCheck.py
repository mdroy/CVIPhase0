#!/usr/bin/python

import datetime
import sys
import os

date_string = sys.argv[1]
date_format = sys.argv[2]

try:
	date_obj = datetime.datetime.strptime(date_string, date_format)
except ValueError:
	print("Incorrect date format, should be", date_format)
