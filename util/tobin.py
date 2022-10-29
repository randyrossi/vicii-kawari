# Get first 64 bytes of colors file and translate to 
# binary for simulator to read
getbinary = lambda x,n: format(x,'b').zfill(n)

c=0
n=0
with open('col.bin', 'rb') as f:
    byte = f.read(1)
    n=n+1
    while byte and n <= 64:
       print (getbinary(int.from_bytes(byte, 'little'),6), end="")
       c=c+1
       n=n+1
       if (c == 4):
           c=0
           print() 
       byte = f.read(1)
