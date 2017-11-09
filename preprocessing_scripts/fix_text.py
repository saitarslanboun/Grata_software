import codecs, sys, re, os

if __name__ == '__main__':
	f = codecs.open("text", encoding="utf-8").read()

	f = f.replace("&gt;", ">")
	f = f.replace("&apos;", "'")
	f = f.replace("&quot;", '"')
	f = f.replace("&lt;", "<")
	f = f.replace("&amp;", "&")

	target = open("fixed_text", "w")
	target.write(f.encode("utf-8"))
	target.close()
