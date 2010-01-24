import sys
import logging
from xml.sax import saxutils, make_parser
from xml.sax.handler import ContentHandler

class XMLParser(ContentHandler):
	def __init__(self):
		logging.basicConfig(level=logging.DEBUG,
							format='%(asctime)s %(levelname)s %(message)s',
							filename='/tmp/xml_test.log',
							filemode='w')
		ContentHandler.__init__(self)
		self.start_time = None
		self.messages = []
		self.tmp_msg = {}

	def startDocument(self):
		self.messages = []
		logging.info('started logging document')

	def startElement(self, name, attrs):
		if name == 'message':
			if 'sender' in attrs:
				self.tmp_msg['sender'] = attrs[u'sender']
				self.tmp_msg['content'] = []
				logging.info('saved sender')

	def characters(self, content):
		if self.tmp_msg:
			self.tmp_msg['content'].append(saxutils.escape(content))
			logging.info('saved content')

	def ignorableWhitespace(self, content):
		if self.tmp_msg:
			self.tmp_msg['content'].append(content)

	def endElement(self, name):
		if name == 'message' and self.tmp_msg:
			self.tmp_msg['content'] = ''.join(self.tmp_msg['content'])
			self.messages.append(self.tmp_msg)
			self.tmp_msg = {}
			logging.info('ended element')
			
	def endDocument(self):
		return self.messages
		logging.info('ended doc.')
