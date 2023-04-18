import sys;
import sklearn;
import sklearn.cluster;

# Load unsigned 8-bit audio data.
# Should be centered at 0x80
if len(sys.argv) < 2:
   print ("Usage: python3 compress.py <file.aif> [max_bytes_uncompressed]")
   sys.exit()

max_bytes = 197632
if len(sys.argv) >= 3:
   max_bytes = int(sys.argv[2])

print("Load samples:{0} ".format(sys.argv[1]));
A=[];
file = open(sys.argv[1],"rb")

# Split the samples into N/X
# vectors where N is the number of
# samples and X is our compression
# ratio (4)
n=0
while True:
   V=file.read(4)
   if len(V) < 4:
       break
   A.append([V[0],V[1],V[2],V[3]])
   n=n+4
   if (n >= max_bytes):
      break

file.close()


print("Run k-means");
# Run k_means cluster algo
a = sklearn.cluster.k_means(
   X=A, n_clusters=256, sample_weight=None,
   init='k-means++',
   n_init=10, max_iter=100,
   verbose=False,
   tol=.001,
   random_state=None,
   copy_x=True,
   algorithm='auto',
   return_n_iter=False)

# Centroids is the codebook. It should be 256 vectors each of length 4.
centroids = a[0]
# Labels are the indices into the codebook. Each entry represents
# 4 samples we can extract from the codebook. It should be an array
# of integers N/4.
labels = a[1]
print (centroids)

print("Save centroids");

# Instead of laying out the data like this:
#                   [0][0],[0][1],[0][2],[0][3],[1][0],[1][2]...
#
# We want 256 bytes [0][0],[1][0],[2][0],[3][0],[4][0]...
#         256 bytes [0][1],[1][1],[2][1],[3][1],[4][1]...
#         256 bytes [0][2],[1][2],[2][2],[3][2],[4][2]...
#         256 bytes [0][3],[1][3],[2][3],[3][3],[4][3]...
#
# So that we can easily index a vector entry using indirect
# indexing mode. i.e.
#         lda $8000,x ; gets first entry in vector
#         lda $8100,x ; gets second entry in vector
#         lda $8200,x ; gets third entry in vector
#         lda $8300,x ; gets fourth entry in vector
ba1=bytearray(len(centroids))
ba2=bytearray(len(centroids))
ba3=bytearray(len(centroids))
ba4=bytearray(len(centroids))
n=0
for i in centroids:
   ba1[n] = int(i[0])
   ba2[n] = int(i[1])
   ba3[n] = int(i[2])
   ba4[n] = int(i[3])
   n=n+1

# This will be 1k of codebook data.
newFile = open("centroids1.bin", "wb")
newFile.write(ba1)
newFile = open("centroids2.bin", "wb")
newFile.write(ba2)
newFile = open("centroids3.bin", "wb")
newFile.write(ba3)
newFile = open("centroids4.bin", "wb")
newFile.write(ba4)

print("Save compressed data stream");
# Now write the labels as the compressed stream data.
ba=bytearray(len(labels))
for i in range(0, len(labels)-1):
   ba[i] = labels[i]

newFile = open("compressed.bin", "wb")
newFile.write(ba)

print("Reconstruct waveform");
# Reconstruct the waveform from the compressed
# data and codebook so we can test what it will
# sound like.
ba=bytearray(len(labels)*4)
n=0
for i in range(0, len(labels)-1):
    ba[n] = int(centroids[labels[i]][0])
    n=n+1
    ba[n] = int(centroids[labels[i]][1])
    n=n+1
    ba[n] = int(centroids[labels[i]][2])
    n=n+1
    ba[n] = int(centroids[labels[i]][3])
    n=n+1

newFile = open("reconstructed.aiff", "wb")
newFile.write(ba)
