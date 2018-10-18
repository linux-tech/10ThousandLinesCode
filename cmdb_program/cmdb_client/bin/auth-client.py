#!/usr/bin/env python
# -*- coding:utf-8 -*-
# Author:Amos Chen
# Date:Created by Amos on 2018/10/18

import os
import sys

BASEDIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.append(BASEDIR)

from src.scripts import client

if __name__ == '__main__':
    client()