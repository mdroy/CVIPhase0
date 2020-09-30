#!/usr/bin/python

import datetime
import sys
import os

file = sys.argv[1]
column = sys.argv[2]
date_format = sys.argv[3]
count = 0

with open(file, "r") as a_file:
    a_file.readline() 
    for line in a_file:
        stripped_line = line.strip()
        date_string = stripped_line.split(",")[int(column)-1]
        if date_string != "":
            count += 1
            try:
                date_obj = datetime.datetime.strptime(date_string, date_format)
            except ValueError:
                print("  ----> Incorrect date format for record ", count)
