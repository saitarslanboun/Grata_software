import codecs, sys, re

def find_between( s, first, last ):
    try:
        start = s.index( first ) + len( first )
        end = s.index( last, start )
        return s[start:end]
    except ValueError:
        return ""

if __name__ == "__main__":
	f = codecs.open(sys.argv[1], encoding="utf-8").read()

	sl = re.findall(r'mid="(.*?)\"', f)
	sl = sorted(list(set(map(int, sl))))

	target = open(sys.argv[1]+".s", "w")
	for a in range(sl[-1]):
		number = a+1
		first = '<mrk mtype="seg" mid="' + str(number) + '">'
		last = "</mrk>"
		sentence = find_between(f, first, last).replace("\n", "") + "\n"
		target.write(sentence.encode("utf-8"))
	target.close()
