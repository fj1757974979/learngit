#coding:utf-8

if __name__ == "__main__":
    f = open("version", "r")
    v = int(f.read())
    f.close()
    f = open("version", "w")
    f.write(str(v+1))
    f.close()
