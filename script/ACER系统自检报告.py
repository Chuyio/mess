#!/usr/bin/env/ python
# -*- coding: utf-8 -*-
# @TIME : 2020/8/28 15:33
# @FILE : ACER系统自检报告.py
import os
import sys
import time
import clr
import psutil
import smtplib
import requests
import json
import numpy as np
import random, jieba
import matplotlib.pyplot as plt
from openpyxl.styles import Font, colors, Alignment
from wordcloud import WordCloud, STOPWORDS
from PIL import Image
from os import path
import cv2
from time import strftime, localtime
from ctypes import *
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from email.header import Header

u = windll.LoadLibrary('user32.dll')
result = u.GetForegroundWindow()
# print(result)
result = "0"
if str(result) == "0":
	BL_MonitorLib_PATH = "E:/ACER_STATUS/module/OpenHardwareMonitorLib.dll"
	BL_BEIJING_IMG = "E:/ACER_STATUS/word/beijing.jpg"
	BL_CIYUN_IMG = "E:/ACER_STATUS/word/chiyun.png"
	BL_FONT_TTF = "E:/ACER_STATUS/font/pmzd.ttf"

	############################### 发现位置 ###############################
	ip_url = 'http://icanhazip.com/'
	headers = {
		'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/78.0.3904.108 Safari/537.36'
	}
	ip_add = requests.get(url=ip_url, headers=headers).text
	ip = ip_add.replace("\n", "")
	dizhi_url = "https://apis.map.qq.com/ws/location/v1/ip?ip={}&key=LJKBZ-SS3C6-PUUS3-EZXPA-5RVKV-DABUE".format(ip)
	response = requests.get(url=dizhi_url, headers=headers).json()

	############################### 采集信息 ###############################
	clr.AddReference(BL_MonitorLib_PATH)  # 加载C#的库这个库网上可以下载
	from OpenHardwareMonitor.Hardware import Computer

	computer_tmp = Computer()  # 实例这这个类
	computer_tmp.CPUEnabled = True
	computer_tmp.GPUEnabled = True  # 获取GPU温度时用
	computer_tmp.HDDEnabled = True
	computer_tmp.RAMEnabled = True  # 获取内存温度时用
	computer_tmp.Open()


	# print(computer_tmp.Hardware[0].Identifier)
	# print(computer_tmp.Hardware[0].Sensors)
	def get_cpu_wendu():
		for a in range(0, len(computer_tmp.Hardware[0].Sensors)):
			# print(computer_tmp.Hardware[0].Sensors[a].Identifier)
			for NMB in range(0, 5):
				NMB = str(NMB)
				if str(computer_tmp.Hardware[0].Sensors[a].Identifier) == "/intelcpu/0/temperature/" + NMB:
					print('CPU{}温度为(℃):'.format(NMB), computer_tmp.Hardware[0].Sensors[a].Value)


	def get_intelcpu_info():
		for a in range(0, len(computer_tmp.Hardware[0].Sensors)):
			# print(computer_tmp.Hardware[0].Sensors[a].Identifier)
			for NMB in range(0, 5):
				NMB = str(NMB)
				if str(computer_tmp.Hardware[0].Sensors[a].Identifier) == "/intelcpu/0/temperature/" + NMB:
					print('CPU{}温度为(℃):'.format(NMB), computer_tmp.Hardware[0].Sensors[a].Value)
			for NMB in range(0, 5):
				NMB = str(NMB)
				if str(computer_tmp.Hardware[0].Sensors[a].Identifier) == "/intelcpu/0/load/" + NMB:
					print('CPU{}负载为(%):'.format(NMB), computer_tmp.Hardware[0].Sensors[a].Value)
			for NMB in range(0, 5):
				NMB = str(NMB)
				if str(computer_tmp.Hardware[0].Sensors[a].Identifier) == "/intelcpu/0/clock/" + NMB:
					print('CPU{}当前频率为(MHz):'.format(NMB), computer_tmp.Hardware[0].Sensors[a].Value)
			for NMB in range(0, 4):
				NMB = str(NMB)
				if str(computer_tmp.Hardware[0].Sensors[a].Identifier) == "/intelcpu/0/power/" + NMB:
					print('CPU{}当前电压为(W):'.format(NMB), computer_tmp.Hardware[0].Sensors[a].Value)
			computer_tmp.Hardware[0].Update()


	def get_gpu_wendu():
		for a in range(0, len(computer_tmp.Hardware[2].Sensors)):
			# print(computer_tmp.Hardware[2].Sensors[a].Identifier)
			if str(computer_tmp.Hardware[2].Sensors[a].Identifier) == "/nvidiagpu/0/temperature/0":
				print('GPU温度为(℃):', computer_tmp.Hardware[2].Sensors[a].Value)


	def get_nvi_info():
		for a in range(0, len(computer_tmp.Hardware[2].Sensors)):
			# print(computer_tmp.Hardware[2].Sensors[a].Identifier)
			if str(computer_tmp.Hardware[2].Sensors[a].Identifier) == "/nvidiagpu/0/temperature/0":
				print('GPU温度为(℃):', computer_tmp.Hardware[2].Sensors[a].Value)
			for NMB in range(0, 4):
				NMB = str(NMB)
				if str(computer_tmp.Hardware[2].Sensors[a].Identifier) == "/nvidiagpu/0/load/" + NMB:
					print('GPU{}负载为(%):'.format(NMB), computer_tmp.Hardware[2].Sensors[a].Value)
			if str(computer_tmp.Hardware[2].Sensors[a].Identifier) == "/nvidiagpu/0/smalldata/1":
				print('GPU内存剩余(MB):', computer_tmp.Hardware[2].Sensors[a].Value)


	# 获取本机磁盘使用率和剩余空间G信息
	def get_disk_info():
		# 循环磁盘分区
		content = ""
		for disk in psutil.disk_partitions():
			# 读写方式 光盘 or 有效磁盘类型
			if 'cdrom' in disk.opts or disk.fstype == '':
				continue
			disk_name_arr = disk.device.split(':')
			disk_name = disk_name_arr[0]
			disk_info = psutil.disk_usage(disk.device)
			# 磁盘剩余空间，单位G
			free_disk_size = disk_info.free // 1024 // 1024 // 1024
			# 当前磁盘使用率和剩余空间G信息
			info = "%s盘使用率：%s%%， 剩余空间：%iG \n" % (disk_name, str(disk_info.percent), free_disk_size)
			# print(info)
			# 拼接多个磁盘的信息
			content = content + info
		print(content)


	def get_cpu_info():
		cpu_percent = psutil.cpu_percent(interval=1)
		cpu_info = "CPU使用率：%i%% \n" % cpu_percent
		print(cpu_info)


	# return cpu_info
	def get_memory_info():
		virtual_memory = psutil.virtual_memory()
		used_memory = virtual_memory.used / 1024 / 1024 / 1024
		free_memory = virtual_memory.free / 1024 / 1024 / 1024
		memory_percent = virtual_memory.percent
		memory_info = "内存使用：%0.2fG，使用率%0.1f%%，剩余内存：%0.2fG" % (used_memory, memory_percent, free_memory)
		print(memory_info)

	output = sys.stdout
	OK_TIME = strftime("%Y%m%d%H%M", localtime())
	filename = OK_TIME + ".txt"
	filepath = "E:/ACER_STATUS/report/" + filename
	outputfile = open(filepath, 'w')
	sys.stdout = outputfile
	get_gpu_wendu()
	get_cpu_wendu()
	print("\n", strftime("%Y-%m-%d %H:%M:%S", localtime()))
	print("ACER笔记本详细状态如下：")
	print("##########################\n")
	print("电脑目前所在位置汇报：")
	print("外网地址：", response['result']['ip'])
	print("所在国家：", response['result']['ad_info']['nation'])
	print("所在省份：", response['result']['ad_info']['province'])
	print("所在市区：", response['result']['ad_info']['city'])
	print("所在地区：", response['result']['ad_info']['district'])
	print("省市编码：", response['result']['ad_info']['adcode'])
	print("经纬坐标：", response['result']['location']['lat'], response['result']['location']['lng'])
	print("\n-----------------------------------\n")
	print("CPU详细信息如下：", computer_tmp.Hardware[0].Name, "\n")
	get_cpu_info()
	get_intelcpu_info()
	print("\n-----------------------------------\n")
	print("内存详细信息如下：", computer_tmp.Hardware[1].Name, "\n")
	get_memory_info()
	print("\n-----------------------------------\n")
	print("硬盘详细信息如下：", computer_tmp.Hardware[3].Name, "\n")
	get_disk_info()
	print("-----------------------------------\n")
	print("显卡详细信息如下：", computer_tmp.Hardware[2].Name, "\n")
	get_nvi_info()
	print("\n-----------------------------------")
	outputfile.close()
	sys.stdout = output

	############################### 制作词云 ###############################
	plt.rcParams["font.sans-serif"] = ["SimHei"]
	plt.rcParams["axes.unicode_minus"] = False


	def get_stopwords():
		dir_path = path.dirname(__file__) if "__file__" in locals() else os.getcwd()
		stopwords_path = os.path.join(dir_path, filepath)
		stopwords = set()
		f = open(stopwords_path, "r")
		line_contents = f.readline()
		while line_contents:
			line_contents = line_contents.replace("\n", "").replace("\t", "").replace("\u3000", "")
			stopwords.add(line_contents)
			line_contents = f.readline()
		return stopwords


	def segment_words(text):
		article_contents = ""
		words = jieba.cut(text, cut_all=False)
		for word in words:
			article_contents += word + " "
		return article_contents


	def drow_mask_wordColud():
		mask = cv2.imread(BL_BEIJING_IMG)
		text = open(path.join(filepath), "r").read().replace("\n", "").replace("\t", "").replace("\u3000", "")
		text = segment_words(text)
		stopwords = get_stopwords()
		wc = WordCloud(scale=4, max_words=2000, mask=mask, background_color="white", font_path=BL_FONT_TTF,
					   stopwords=stopwords, margin=10, random_state=1).generate(text)
		wc.to_file(BL_CIYUN_IMG)


	if __name__ == "__main__":
		drow_mask_wordColud()

	############################### 压缩图片 ###############################
	image = Image.open(BL_CIYUN_IMG)
	image_w, image_h = image.size
	image.thumbnail((image_w / 8, image_h / 8))
	image.save(BL_CIYUN_IMG)

	############################### 发送邮件 ###############################
	smtpserver = 'smtp.163.com'
	username = 'goodmoodwjl@163.com'
	password = 'wangjinlong666'
	sender = 'goodmoodwjl@163.com'
	receiver = '1591458779@qq.com'
	subject = 'ACER笔记本状态报告'
	subject = Header(subject, 'utf-8').encode()
	# msg = MIMEMultipart('mixed')
	NMB = random.randint(1, 6)
	msg = MIMEMultipart('alternative')
	msg['Subject'] = subject
	msg['From'] = 'goodmoodwjl@163.com'
	msg['To'] = "1591458779@qq.com"
	f = open(filepath, 'r')
	status_text = ''' '''
	while True:
		line = f.readline()
		status_text += line.strip() + '<br>'
		if not line:
			break
	f.close()
	# text_plain = MIMEText(status_text, 'plain', 'utf-8')
	# msg.attach(text_plain)
	fp = open(BL_CIYUN_IMG, 'rb')
	msgImage = MIMEImage(fp.read())
	fp.close()
	msgImage.add_header('Content-ID', '<image1>')
	msg.attach(msgImage)
	dog_path = "E:/ACER_STATUS/word/dog{}.jpg".format(NMB)
	fp = open(dog_path, 'rb')
	msgImage = MIMEImage(fp.read())
	fp.close()
	msgImage.add_header('Content-ID', '<image2>')
	msg.attach(msgImage)
	html_ciyun = """
	<html>  
	  <head></head>  
	  <body>  
	    <p>
	       <br><img src="cid:image1"></br>
		   <br>{}</br>
		   <img src="cid:image2">
	       <br> 
	    </p> 
	  </body>  
	</html> 
	""".format(status_text)
	img1_html = MIMEText(html_ciyun, 'html', 'utf-8')
	msg.attach(img1_html)

	smtp = smtplib.SMTP()
	smtp.connect('smtp.163.com')
	smtp.login(username, password)
	smtp.sendmail(sender, receiver, msg.as_string())
	smtp.quit()
