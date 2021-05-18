/* Sigma.lua
 *
 * Compute sum = 1 + 2 + ... + n
 */

// variables
const integer n = 10
integer sum = 0
integer index = 0
  
while (index <= n) do
  sum = sum + index
  index = index + 1
end 
print "The sum is "
println sum
