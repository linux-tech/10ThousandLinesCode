#!/usr/bin/env python
# -*- coding:utf-8 -*-
# Author:Amos Chen
# Date:Created by Amos on 2018/10/18

from config import  settings
import hashlib
import time
import requests
from lib.log import Logger
import json

class AutoBase(object):
    def __init__(self):
        self.asset_api = settings.ASSET_API
        self.key = settings.KEY
        self.key_name = settings.AUTH_KEY_NAME

    # 接口认证
    def auth_key(self):
        ha = hashlib.md5(self.key.encode('utf-8'))
        time_span = time.time()
        ha.update(bytes("%s|%f" % (self.key, time_span), encoding='utf-8'))
        encryption = ha.hexdigest()
        result = "%s|%f" % (encryption,time_span)

        return {self.key_name: result}

    def get_asset(self):

        # 通过 GET 方式从后台获取未采集到的数据
        """
        get方式向获取未采集的资产
        :return: {"data": [{"hostname": "c1.com"}, {"hostname": "c2.com"}], "error": null, "message": null, "status": true}
        """

        try:
            headers = {}
            headers.update(self.auth_key())
            response = requests.get(
                url=self.asset_api,
                headers=headers
            )
        except Exception as e:
            response = e
        return response.json()

    def post_asset(self, msg, callback=None):

        """
        post方式向接口提交资产信息
        :param msg:
        :param callback:
        :return:
        """
        status = True
        try:
            headers = {}
            headers.update(self.auth_key())
            response = requests.post(
                url=self.asset_api,
                headers=headers,
                json=msg
            )
        except Exception as e:
            response = e
            status = False
        if callback:
            callback(status, response)

    def callback(self, status, response):

        """
        提交资产后的回调函数
        :param status: 是否请求成功
        :param response: 请求成功，则是响应内容对象；请求错误，则是异常对象
        :return:
        """
        if not status:
            Logger().log(str(response), False)
            return
        ret = json.loads(response.text)
        if ret['code'] == 1000:
            Logger().log(ret['message'], True)
        else:
            Logger().log(ret['message'], False)

    def process(self):

        """
        派生类需要继承此方法，用于处理请求的入口
        :return:
        """
        raise NotImplementedError("you must implement process method")



class AutoAgent(object):
    pass


class AutoSSH(object):
    pass


class AutoSalt(object):
    pass