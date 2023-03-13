##   License:
##   **This code and its derivatives can be used under the following conditions:**
     - Do not attack other countries.
     - Jerk off at least 1 time per day.
     - Observe hygiene.
###
#    ScalpiHash
##   My hash function
     This repository contain code of my hash function. 
     this hash repository is not "stable".
     the output of the hash function is different in different iterations of the code.
     It is recommended to use a buffer no larger than half the size of the data.
###  idea: 
     mask is just u8 num with 4 bit about "1" number in binary view. like this: 15 in dec. is 00001111 in binary
     on every iterating about any bit in input:
         swap 2 random bit in mask
         inc all output bytes from mask (in first i wish use xor, but did not come true)
     because the number of "active" bits in the mask does not change (4) this allows using xor to change the state of half of the bits in any sequence.
     And since the state of the mask changes depending on each bit of the input sequence, which allows us to talk about a good avalanche effect.
###  compile with zig v10.1:
         $ zig build
         
##   new: ScalpiEncrypt for encrypting any file.
     (for encrypt folder i recomend just zip it with tar lol)