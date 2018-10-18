#!/usr/bin/env python
# -*- coding:utf-8 -*-
# Author:Amos Chen
# Date:Created by Amos on 2018/10/18

import hashlib
import time



KEY = 'hello world'

ha = hashlib.md5(KEY.encode(encoding='utf-8'))
time_span = time.time()
print(type(time_span))

msg = bytes("%s|%f" % (KEY, time_span), encoding='utf-8')
str = "%s|%f" % (KEY, time_span)

print(msg)
print(str.encode(encoding='utf-8'))

print(ha.update(b'hello'))
encryption = ha.hexdigest()
print(encryption)
