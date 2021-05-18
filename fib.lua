/* fib.lua
 *
 * This test program computes the Nth Fibonacci number
 */

// variables
integer n  = 8
integer Fn = 1
integer FNminus1 = 1
integer temp

// compute the nth Fibonacci number
while (n > 2) do
  temp = Fn
  Fn = Fn + FNminus1
  FNminus1 = temp
  n = n - 1
end

/* print result */
print "Result of computation: "
println n
