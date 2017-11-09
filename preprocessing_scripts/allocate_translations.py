import codecs, sys, re

if __name__ == "__main__":
	f = codecs.open(sys.argv[1], encoding="utf-8").read()
	tf = codecs.open("ltranslation", encoding="utf-8").readlines()

	sl = re.findall(r'mid="(.*?)\"', f)
	sl = sorted(list(set(map(int, sl))))

	target = open(sys.argv[1]+".translated", "w")
	for a in range(sl[-1]):
		number = a + 1
		first = '<mrk mtype="seg" mid="' + str(number) + '"/>'
		last = '<mrk mtype="seg" mid="' + str(number) + '">' + tf[a].replace("\n", "") + '</mrk>'
		f = f.replace(first, last)
	target.write(f.encode("utf-8"))
	target.close()
