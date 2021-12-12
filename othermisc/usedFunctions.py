import random
import string
import math

def randomString(length):
    letters = string.ascii_letters
    result_str = ''.join(random.choice(letters) for i in range(length))
    return result_str

def clustered(x,numRows):
    return math.floor(x -1)/numRows

def scattered(x,numRows):
    return abs((x -1 % numRows))* 1.0

def randomised(seed,numRows):
    random.seed(seed)
    return abs(random.randint(0, numRows) % numRows) * 1.0

def padString(x,chars,length):
    n = int(x) + 1
    result_str = ''.join(random.choice(chars) for i in range(length-n)) + str(x)
    return result_str
def padSingleChar(chars,length):
    result_str = ''.join(chars for i in range(length))
    return result_str

def println(lst):
    for ll in lst:
      print(ll[0])

