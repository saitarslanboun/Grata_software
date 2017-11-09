import codecs

if __name__ == "__main__":
	f = codecs.open("recovered", encoding="utf-8").read()
	f = f.replace("@@ ", "")
	f = f.replace("@@", "")
	newf = open("debpe", "w")
	newf.write(f.encode("utf-8"))
	newf.close()
