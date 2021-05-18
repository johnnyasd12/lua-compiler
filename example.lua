/*
 * Example with Functions
 */

// variables
integer a = 5
integer c

// function declaration
function integer add(integer a, integer b)
  return a+b
end

// main statements
c = add(a, 10)
if (c > 10) then
  print -c
else 
  print c
end
println "Hello World"
